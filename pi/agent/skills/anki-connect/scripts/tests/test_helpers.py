"""Offline tests: python3 -m unittest discover -s scripts/tests (from the skill)."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]
MOCK_CURL = r'''#!/usr/bin/env python3
import json, os, sys
request = json.load(sys.stdin)
with open(os.environ['MOCK_LOG'], 'a') as log:
    log.write(json.dumps({'request': request, 'args': sys.argv[1:]}) + '\n')
mode = os.environ.get('MOCK_MODE', '')
action = request['action']
assert request['version'] == 6
assert request.get('key') == os.environ.get('ANKI_CONNECT_API_KEY')
if mode == 'transport': sys.exit(7)
if mode == 'empty-response': sys.exit(0)
if mode == 'malformed': print('not JSON'); sys.exit(0)
if mode == 'envelope': print('{}'); sys.exit(0)
if mode == 'multiple': print('{}\n{}'); sys.exit(0)
if mode == 'api-error' or (mode == 'count-error' and action == 'findNotes'):
    print(json.dumps({'result': None, 'error': 'mock API failure'})); sys.exit(0)
if mode == 'wrong-type':
    print(json.dumps({'result': False, 'error': None})); sys.exit(0)
if action == 'deckNames':
    result = [os.environ.get('MOCK_DECK', 'Korean Vocabulary')]
elif action == 'findCards':
    result = [] if mode == 'empty' else [11, 12, 13]
elif action == 'findNotes':
    result = [] if mode == 'empty' else list(range(1001)) if mode in ('large', 'late-error', 'missing-note') else [1, 2]
elif action == 'notesInfo':
    ids = request['params']['notes']
    if mode == 'late-error' and ids[0] == 500:
        print(json.dumps({'result': None, 'error': 'later batch failed'})); sys.exit(0)
    result = [{'noteId': n, 'modelName': 'Basic', 'tags': ['test'], 'cards': [n+10000],
               'fields': {'Front': {'value': '한국<br>말', 'order': 0}}} for n in ids]
    if mode == 'missing-note': result[-1] = {}
else:
    raise AssertionError('Unexpected action: ' + action)
print(json.dumps({'result': result, 'error': None}))
'''


class HelpersTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        curl = root / 'curl'
        curl.write_text(MOCK_CURL)
        curl.chmod(0o755)
        self.log = root / 'calls.jsonl'
        self.env = {**os.environ, 'PATH': f'{root}:{os.environ["PATH"]}',
                    'MOCK_LOG': str(self.log), 'ANKI_CONNECT_API_KEY': 'test-only-secret',
                    'ANKI_CONNECT_URL': 'http://127.0.0.1:9999'}

    def run_script(self, script, *args, mode=''):
        return subprocess.run(['bash', str(SCRIPTS / script), *args], text=True,
                              capture_output=True, env={**self.env, 'MOCK_MODE': mode})

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_counts_are_separate(self):
        result = self.run_script('deck-count.sh', 'Korean Vocabulary')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {'deck': 'Korean Vocabulary',
                         'includesSubdecks': True, 'cards': 3, 'notes': 2})
        self.assertEqual(len(self.calls()), 3)
        for call in self.calls():
            self.assertIn('http://127.0.0.1:9999', call['args'])
            self.assertNotIn('test-only-secret', ' '.join(call['args']))
        self.assertEqual(self.calls()[1]['request']['params'],
                         {'query': 'deck:"Korean Vocabulary"'})

    def test_literal_deck_name(self):
        name = '한국::A_"B"*\\C (test)'
        self.env['MOCK_DECK'] = name
        result = self.run_script('deck-count.sh', name)
        self.assertEqual(result.returncode, 0, result.stderr)
        escaped = name.replace('\\', '\\\\').replace('"', '\\"').replace('*', '\\*').replace('_', '\\_')
        self.assertEqual(self.calls()[1]['request']['params']['query'], f'deck:"{escaped}"')

    def test_missing_and_reserved_decks(self):
        result = self.run_script('deck-count.sh', 'Typo')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertEqual(len(self.calls()), 1)
        self.env['MOCK_DECK'] = 'filtered'
        result = self.run_script('deck-count.sh', 'filtered')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')

    def test_fetch_chunking_and_fields(self):
        query = 'deck:"한국" tag:test -is:suspended'
        result = self.run_script('fetch-notes.sh', query, mode='large')
        self.assertEqual(result.returncode, 0, result.stderr)
        notes = json.loads(result.stdout)
        self.assertEqual([n['noteId'] for n in notes], list(range(1001)))
        self.assertEqual(notes[0]['fields']['Front']['value'], '한국<br>말')
        calls = self.calls()
        self.assertEqual(calls[0]['request']['params'], {'query': query})
        self.assertEqual([len(c['request']['params']['notes']) for c in calls[1:]], [500, 500, 1])

    def test_empty_results(self):
        result = self.run_script('fetch-notes.sh', 'tag:nothing', mode='empty')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [])
        self.assertEqual(len(self.calls()), 1)  # No unnecessary notesInfo call.
        result = self.run_script('deck-count.sh', 'Korean Vocabulary', mode='empty')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['cards'], 0)
        self.assertEqual(json.loads(result.stdout)['notes'], 0)

    def test_no_auth_or_endpoint_override(self):
        self.env.pop('ANKI_CONNECT_API_KEY')
        self.env.pop('ANKI_CONNECT_URL')
        result = self.run_script('fetch-notes.sh', 'tag:test')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('key', self.calls()[0]['request'])
        self.assertIn('http://127.0.0.1:8765', self.calls()[0]['args'])

    def test_errors_emit_no_partial_json(self):
        for script in ('fetch-notes.sh', 'deck-count.sh'):
            for mode in ('transport', 'empty-response', 'malformed', 'envelope',
                         'multiple', 'api-error', 'wrong-type'):
                with self.subTest(script=script, mode=mode):
                    result = self.run_script(script, 'Korean Vocabulary', mode=mode)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(result.stdout, '')
        result = self.run_script('deck-count.sh', 'Korean Vocabulary', mode='count-error')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        for mode in ('late-error', 'missing-note'):
            result = self.run_script('fetch-notes.sh', 'tag:test', mode=mode)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, '')

    def test_usage_without_network(self):
        for script in ('fetch-notes.sh', 'deck-count.sh'):
            for args in ((), ('',), ('one', 'two')):
                self.assertEqual(self.run_script(script, *args).returncode, 2)
            self.assertEqual(self.run_script(script, '--help').returncode, 0)
        self.assertFalse(self.log.exists())
