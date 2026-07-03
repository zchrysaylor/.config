// Worked example to mimic. The template lives one directory up, so compile
// with the skill directory as the Typst root:
//   (from the skill dir)  typst compile --root . resources/example.typ
//   (from the repo root)  typst compile --root skills/iyagi-incubator skills/iyagi-incubator/resources/example.typ
// Generated instance files use an absolute import + `--root /` instead; see SKILL.md.
#import "../iyagi-template.typ": iyagi-sheet

#iyagi-sheet(
  topic: "first love",
  level: "2A",
  korean: [
    민수는 고등학교 때 첫사랑이 있었어요. 그 사람은 같은 반 친구 지민이에요. 지민은 조용하지만 웃는 얼굴이 아주 예뻤어요.

    민수는 매일 학교에서 지민을 보고 싶었어요. 그래서 아침에 일찍 학교에 갔어요. 어느 날, 지민이 교실에서 책을 읽고 있었어요. 민수는 지민한테 "이 책 재미있어요?"라고 물었어요. 지민은 웃고 "네, 정말 좋아요. 다음에 같이 도서관에 갈래요?"라고 말했어요.

    민수는 너무 기뻤지만 말을 잘할 수 없었어요. 그래도 작은 목소리로 "네, 갈게요"라고 대답했어요. 그날부터 민수는 학교에 가는 것이 더 즐거웠어요.
  ],
  english: [
    Minsu had a first love in high school. That person was Jimin, a friend in the same class. Jimin was quiet, but her smiling face was very pretty.

    Minsu wanted to see Jimin at school every day. So he went to school early in the morning. One day, Jimin was reading a book in the classroom. Minsu asked Jimin, "Is this book interesting?" Jimin smiled and said, "Yes, it's really good. Do you want to go to the library together next time?"

    Minsu was very happy, but he couldn't speak well. Still, in a small voice, he answered, "Yes, I'll go." From that day on, going to school became more enjoyable for Minsu.
  ],
  grammar: (
    (formula: "있어요", sentence: "민수는 고등학교 때 첫사랑이 있었어요.", meaning: "Minsu had a first love."),
    (formula: "N-이에요/예요", sentence: "그 사람은 같은 반 친구 지민이에요.", meaning: "That person is Jimin."),
    (formula: "A/V-지만", sentence: "지민은 조용하지만 웃는 얼굴이 아주 예뻤어요.", meaning: "Jimin was quiet, but her smile was pretty."),
    (formula: "V-고 싶어요", sentence: "민수는 매일 학교에서 지민을 보고 싶었어요.", meaning: "Minsu wanted to see Jimin."),
    (formula: "V-고 있어요", sentence: "지민이 교실에서 책을 읽고 있었어요.", meaning: "Jimin was reading a book."),
    (formula: "V-(으)ㄹ 수 없다", sentence: "말을 잘할 수 없었어요.", meaning: "He couldn't speak well."),
  ),
  vocab: (
    ("첫사랑", "first love"),
    ("고등학교", "high school"),
    ("같은 반", "same class"),
    ("조용하다", "to be quiet"),
    ("웃는 얼굴", "smiling face"),
    ("매일", "every day"),
    ("일찍", "early"),
    ("교실", "classroom"),
    ("도서관", "library"),
    ("대답하다", "to answer"),
  ),
  questions: (
    [민수의 첫사랑은 누구예요?],
    [지민은 교실에서 무엇을 하고 있었어요?],
    [Rewrite this sentence in Korean: "Minsu wanted to see Jimin every day."],
  ),
)
