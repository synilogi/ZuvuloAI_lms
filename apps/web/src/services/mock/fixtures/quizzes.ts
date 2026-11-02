import type { Quiz, QuizQuestion, QuizSettings } from '@syniastrolms/domain';
import { defaultQuizSettings } from '@syniastrolms/domain';
import { courses } from './catalog';

/* ─── Question bank ────────────────────────────────────────────────────── */

type Spec =
  | { kind: 'choice'; prompt: string; options: string[]; correct: number[]; explanation: string; points?: number }
  | { kind: 'truth'; prompt: string; isTrue: boolean; explanation: string; points?: number }
  | { kind: 'short'; prompt: string; answers: string[]; explanation: string; points?: number };

const choice = (prompt: string, options: string[], correct: number | number[], explanation: string, points = 1): Spec => ({
  kind: 'choice',
  prompt,
  options,
  correct: Array.isArray(correct) ? correct : [correct],
  explanation,
  points,
});
const truth = (prompt: string, isTrue: boolean, explanation: string, points = 1): Spec => ({ kind: 'truth', prompt, isTrue, explanation, points });
const short = (prompt: string, answers: string[], explanation: string, points = 1): Spec => ({ kind: 'short', prompt, answers, explanation, points });

const BANK: Record<string, Spec[]> = {
  intro: [
    choice(
      'What does a birth chart record?',
      [
        'The positions of the grahas at the moment and place of birth',
        'The day of the week a person was born',
        'The constellations visible at midnight',
        'A person’s lunar month of birth',
      ],
      0,
      'A chart is a map of the sky — the grahas in signs and houses — for one moment and one place.',
    ),
    choice(
      'Which zodiac does Jyotish use?',
      ['Tropical', 'Sidereal', 'Heliocentric', 'Draconic'],
      1,
      'Jyotish measures signs against the fixed stars, correcting for precession with the ayanamsha.',
    ),
    truth(
      'The ayanamsha is the difference between the tropical and sidereal zodiacs.',
      true,
      'It is currently about 24°, which is why many Sun signs shift back by a sign in Jyotish.',
    ),
    short(
      'How many nakshatras divide the zodiac?',
      ['27', 'twenty-seven', 'twenty seven'],
      'Twenty-seven lunar mansions of 13°20′ each — a 28th, Abhijit, is used only in muhurta.',
    ),
    choice(
      'Which of these is not one of the five limbs of the panchang?',
      ['Tithi', 'Vara', 'Lagna', 'Karana'],
      2,
      'The five limbs are tithi, vara, nakshatra, yoga and karana. The lagna belongs to a chart, not the panchang.',
    ),
  ],
  planets: [
    choice(
      'Which graha is the natural atmakaraka, signifying the soul?',
      ['Chandra', 'Surya', 'Guru', 'Shani'],
      1,
      'Surya represents the self and vitality; Chandra represents the mind.',
    ),
    choice('In which sign is Saturn exalted?', ['Capricorn', 'Aquarius', 'Libra', 'Aries'], 2, 'Shani is exalted in Libra and debilitated in Aries.'),
    choice(
      'Which grahas are the natural benefics?',
      ['Jupiter', 'Venus', 'Mars', 'Well-associated Mercury'],
      [0, 1, 3],
      'Jupiter and Venus are natural benefics; Mercury is benefic when well associated, and a waxing Moon is too.',
      2,
    ),
    truth(
      'Rahu and Ketu own signs in the classical Parashari scheme.',
      false,
      'The nodes are shadow planets without sign lordship in Parashara’s scheme, though some traditions assign co-lordships.',
    ),
    short('Which graha rules both Gemini and Virgo?', ['Mercury', 'Budha'], 'Budha rules Gemini and Virgo, and is exalted in Virgo.'),
    choice(
      'Which graha moves fastest through the zodiac?',
      ['Mercury', 'Venus', 'The Moon', 'The Sun'],
      2,
      'Chandra crosses a sign in about two and a quarter days.',
    ),
  ],
  houses: [
    choice('Which houses are the kendras?', ['1, 4, 7, 10', '1, 5, 9', '6, 8, 12', '3, 6, 10, 11'], 0, 'Kendras are the angular houses: 1, 4, 7 and 10.'),
    choice('Which houses are trikonas?', ['2, 6, 10', '1, 5, 9', '4, 8, 12', '3, 7, 11'], 1, 'The trikonas — houses of dharma — are 1, 5 and 9.'),
    choice('Which houses are called dusthanas?', ['6', '8', '10', '12'], [0, 1, 3], 'The sixth, eighth and twelfth are the houses of difficulty.', 2),
    choice(
      'Which house governs home and mother?',
      ['Second', 'Fourth', 'Seventh', 'Ninth'],
      1,
      'The fourth house is the home, the mother and inner contentment.',
    ),
    truth('The lagna is both the first house and the self.', true, 'The ascendant sign sets the first house and describes the body and self.'),
    short(
      'For an Aries lagna, which graha rules the tenth house?',
      ['Saturn', 'Shani'],
      'Counting from Aries, the tenth sign is Capricorn, ruled by Saturn.',
      2,
    ),
    choice(
      'Which house is associated with courage and younger siblings?',
      ['Third', 'Fifth', 'Eleventh', 'Sixth'],
      0,
      'The third house is effort, courage and younger siblings.',
    ),
    choice(
      'The second house signifies…',
      ['Wealth, speech and family', 'Enemies and debts', 'Travel and spirituality', 'Children and intelligence'],
      0,
      'Dhana bhava: accumulated wealth, speech, food and the family of origin.',
    ),
  ],
  signs: [
    choice(
      'Which signs are movable (chara)?',
      ['Aries', 'Cancer', 'Leo', 'Capricorn'],
      [0, 1, 3],
      'Aries, Cancer, Libra and Capricorn are the movable signs.',
      2,
    ),
    choice('Which element is Scorpio?', ['Fire', 'Earth', 'Air', 'Water'], 3, 'Scorpio is a fixed water sign, ruled by Mars.'),
    truth('Leo is ruled by the Sun and has no second ruler in Parashari astrology.', true, 'Leo is Surya’s only sign.'),
    short('Which graha is exalted in Cancer?', ['Jupiter', 'Guru'], 'Guru is exalted in Cancer and debilitated in Capricorn.'),
  ],
  nakshatra: [
    choice(
      'Which graha is the lord of Ashwini?',
      ['Ketu', 'Venus', 'Sun', 'Moon'],
      0,
      'The Vimshottari sequence begins with Ketu ruling Ashwini, Magha and Mula.',
    ),
    choice('Rohini is ruled by…', ['Mars', 'The Moon', 'Rahu', 'Jupiter'], 1, 'Rohini is ruled by Chandra — the Moon is exalted in its early degrees.'),
    short('How many padas does each nakshatra have?', ['4', 'four'], 'Each 13°20′ nakshatra has four padas of 3°20′, each linked to a navamsha.'),
    truth(
      'The Moon’s nakshatra at birth sets the starting Vimshottari dasha.',
      true,
      'The dasha begins with the lord of the Moon’s nakshatra, balanced by how far the Moon has travelled through it.',
    ),
    choice('Which deity presides over Krittika?', ['Agni', 'Indra', 'Yama', 'Brahma'], 0, 'Krittika, the cutting flame, is presided over by Agni.'),
  ],
  panchang: [
    choice(
      'A tithi is completed when the Moon gains how many degrees on the Sun?',
      ['6°', '12°', '13°20′', '30°'],
      1,
      'Each tithi is a 12° separation; thirty make a lunar month.',
    ),
    truth('Rahu kalam falls at the same clock time every day of the week.', false, 'Rahu kalam moves with the weekday and with local sunrise and sunset.'),
    short('How many karanas make up a tithi?', ['2', 'two'], 'Each tithi has two karanas — half-tithis of 6°.'),
    choice('Which vara is ruled by Jupiter?', ['Tuesday', 'Thursday', 'Friday', 'Saturday'], 1, 'Guruvara, Thursday, is Jupiter’s day.'),
    choice(
      'Which limb of the panchang is formed by adding the longitudes of the Sun and the Moon?',
      ['Yoga', 'Karana', 'Tithi', 'Nakshatra'],
      0,
      'The 27 yogas come from the sum of solar and lunar longitudes.',
    ),
  ],
  dasha: [
    short(
      'How many years is the full Vimshottari cycle?',
      ['120', 'one hundred twenty', 'one hundred and twenty'],
      'Vimshottari means "of 120": the nine periods add up to 120 years.',
    ),
    choice('Which mahadasha is the longest?', ['Saturn', 'Venus', 'Rahu', 'Jupiter'], 1, 'Venus runs for 20 years, followed by Saturn (19) and Rahu (18).'),
    choice(
      'The antardasha sequence within a mahadasha begins with…',
      ['The mahadasha lord itself', 'Ketu', 'The Sun', 'The lagna lord'],
      0,
      'Each mahadasha opens with its own antardasha, then follows the Vimshottari order.',
    ),
    truth(
      'A well-placed yogakaraka generally gives good results in its dasha.',
      true,
      'A yogakaraka rules both a kendra and a trikona; its periods tend to deliver status and growth.',
    ),
    choice(
      'Which transits are used for the "double transit" confirmation of events?',
      ['Jupiter and Saturn', 'Sun and Moon', 'Mars and Rahu', 'Mercury and Venus'],
      0,
      'An event is likely when both Jupiter and Saturn aspect or occupy the relevant house or lord.',
    ),
  ],
  yogas: [
    choice(
      'A raja yoga is formed by a connection between lords of…',
      ['A kendra and a trikona', 'Two dusthanas', 'The 2nd and 12th', 'The 3rd and 6th'],
      0,
      'Kendra lords give power and trikona lords give fortune; their union is a raja yoga.',
    ),
    choice(
      'Ruchaka yoga involves which graha in a kendra in its own or exaltation sign?',
      ['Mars', 'Mercury', 'Jupiter', 'Saturn'],
      0,
      'Ruchaka is Mars; Bhadra is Mercury, Hamsa Jupiter, Malavya Venus and Shasha Saturn.',
    ),
    truth(
      'Gajakesari yoga is formed when Jupiter is in a kendra from the Moon.',
      true,
      'The elephant-lion yoga: Guru in the 1st, 4th, 7th or 10th from Chandra.',
    ),
    short(
      'What name is given to the yoga when the Moon has no planets in the 2nd or 12th from it?',
      ['Kemadruma', 'Kemadruma yoga'],
      'Kemadruma describes an isolated Moon; it is often cancelled by other factors.',
    ),
  ],
  transits: [
    choice(
      'Sade sati is Saturn’s transit through…',
      ['The 12th, 1st and 2nd from the Moon', 'The 8th from the Moon', 'The 4th and 8th from the lagna', 'The 10th house'],
      0,
      'The seven-and-a-half years as Saturn crosses the sign before, of and after the natal Moon.',
    ),
    truth(
      'In ashtakavarga, a sign with more bindus supports a transit better.',
      true,
      'Higher bindu counts indicate more supportive transits through that sign.',
    ),
    short(
      'About how many years does Jupiter take to transit one sign?',
      ['1', 'one', 'a year', 'one year'],
      'Guru takes roughly a year per sign and twelve years per cycle.',
    ),
    choice(
      'Vedha in gochara refers to…',
      ['An obstruction that cancels a transit’s result', 'A retrograde transit', 'An eclipse', 'A planet changing signs'],
      0,
      'A planet in the vedha position blocks the effect of a favourable transit.',
    ),
  ],
  navamsha: [
    short('Into how many parts is each sign divided for the navamsha?', ['9', 'nine'], 'Navamsha means "ninth part": 3°20′ each.'),
    choice(
      'A planet is vargottama when…',
      ['It occupies the same sign in the rashi and navamsha', 'It is exalted in the navamsha', 'It is retrograde', 'It aspects the lagna'],
      0,
      'Vargottama planets are strengthened by holding the same sign in both charts.',
    ),
    choice('Which divisional chart is used for career?', ['D7', 'D9', 'D10', 'D12'], 2, 'The dashamsha, D10, is the chart of profession and public life.'),
    truth(
      'The navamsha is mainly used to judge children.',
      false,
      'The navamsha is read for marriage, dharma and planetary strength; the saptamsha (D7) is for children.',
    ),
  ],
  kp: [
    short('Into how many sub divisions does KP divide the zodiac?', ['249'], 'Krishnamurti Paddhati uses 249 subs based on Vimshottari proportions.'),
    choice('KP uses which house system?', ['Whole sign', 'Equal house', 'Placidus', 'Sripati'], 2, 'KP uses Placidus cusps.'),
    truth('In KP, the cuspal sub-lord decides whether a matter will fructify.', true, 'The sub-lord of the relevant cusp is the deciding factor.'),
    choice(
      'Ruling planets are taken at…',
      ['The moment of judgement', 'Birth', 'Sunrise', 'The new moon'],
      0,
      'Ruling planets — day lord, Moon’s sign, star and sub lords, lagna lords — are read at the moment of judgement.',
    ),
  ],
  jaimini: [
    short('How many chara karakas are used in the common seven-karaka scheme?', ['7', 'seven'], 'From atmakaraka to darakaraka, excluding the nodes.'),
    choice(
      'The atmakaraka is the graha with…',
      ['The highest degree in its sign', 'The lowest degree', 'The most bindus', 'Exaltation'],
      0,
      'The planet furthest advanced in its sign becomes the atmakaraka.',
    ),
    truth(
      'In Jaimini, aspects are cast by signs rather than by planets.',
      true,
      'Rashi drishti: movable signs aspect fixed signs except the adjacent one, and so on.',
    ),
    choice(
      'The arudha lagna shows…',
      ['How a person is perceived', 'Longevity', 'Siblings', 'The ninth house of fortune'],
      0,
      'The arudha lagna is the image the world holds of the native.',
    ),
  ],
  muhurta: [
    choice(
      'Which of these is part of panchang shuddhi for an election?',
      ['A favourable tithi', 'A favourable nakshatra', 'The native’s atmakaraka', 'A suitable vara'],
      [0, 1, 3],
      'Panchang shuddhi checks tithi, vara, nakshatra, yoga and karana.',
      2,
    ),
    truth('Tarabala is calculated from the native’s birth nakshatra.', true, 'Count from the janma nakshatra to the day’s nakshatra and divide by nine.'),
    choice(
      'Which lagna quality is generally preferred for a griha pravesh?',
      ['Fixed sign', 'Movable sign', 'Any dual sign', 'A sign with Mars'],
      0,
      'Fixed signs support permanence — a good fit for entering a home.',
    ),
    short(
      'What is the name of the auspicious midday period used when no better muhurta is available?',
      ['Abhijit', 'Abhijit muhurta'],
      'Abhijit muhurta falls around local noon and is considered broadly supportive.',
    ),
  ],
  lalkitab: [
    truth('The Lal Kitab chart uses Aries as the fixed first house.', true, 'Lal Kitab fixes Aries in the first house regardless of the lagna.'),
    choice(
      'In Lal Kitab, a "sleeping" house is one that…',
      ['Is not aspected by any planet', 'Contains Saturn', 'Is the twelfth house', 'Holds the Moon'],
      0,
      'Houses without aspecting planets are said to be asleep.',
    ),
    short('Which book gives the tradition its name?', ['Lal Kitab', 'The Red Book', 'Red Book'], 'Lal Kitab means "the red book".'),
  ],
};

let n = 0;
function build(topic: string, quizId: string): QuizQuestion[] {
  return BANK[topic].map((spec) => {
    const id = `${quizId}-q${++n}`;
    if (spec.kind === 'short') {
      return {
        id,
        type: 'short',
        prompt: spec.prompt,
        options: [],
        correct: [],
        acceptedAnswers: spec.answers,
        points: spec.points ?? 1,
        explanation: spec.explanation,
        required: true,
      };
    }
    if (spec.kind === 'truth') {
      return {
        id,
        type: 'true-false',
        prompt: spec.prompt,
        options: [
          { id: `${id}-true`, text: 'True' },
          { id: `${id}-false`, text: 'False' },
        ],
        correct: [spec.isTrue ? `${id}-true` : `${id}-false`],
        acceptedAnswers: [],
        points: spec.points ?? 1,
        explanation: spec.explanation,
        required: true,
      };
    }
    const options = spec.options.map((text, i) => ({ id: `${id}-o${i + 1}`, text }));
    return {
      id,
      type: spec.correct.length > 1 ? 'multiple' : 'single',
      prompt: spec.prompt,
      options,
      correct: spec.correct.map((i) => options[i].id),
      acceptedAnswers: [],
      points: spec.points ?? 1,
      explanation: spec.explanation,
      required: true,
    };
  });
}

/* ─── Quizzes: one per quiz lesson, plus drafts in progress ────────────── */

const LESSON_TOPICS: Record<string, string[]> = {
  'm1-l5': ['intro'],
  'm3-l8': ['houses'],
  'm7-l3': ['planets', 'houses', 'signs', 'nakshatra'],
  'intro-jyotish-c2-l3': ['intro'],
  'panchang-c3-l3': ['panchang'],
  'nakshatra-depth-c5-l3': ['nakshatra'],
  'dasha-c4-l3': ['dasha'],
  'yogas-c4-l4': ['yogas'],
  'navamsha-c3-l4': ['navamsha'],
  'gochara-c3-l3': ['transits'],
  'jaimini-c4-l5': ['jaimini'],
  'kp-system-c3-l4': ['kp'],
  'muhurta-c3-l4': ['muhurta'],
  'lal-kitab-c2-l2': ['lalkitab'],
};

function quizForLesson(lessonId: string): Quiz | null {
  for (const course of courses) {
    for (const chapter of course.chapters) {
      const lesson = chapter.lessons.find((l) => l.id === lessonId);
      if (!lesson) continue;
      const id = `quiz-${lessonId}`;
      const final = /final/i.test(lesson.title);
      const settings: QuizSettings = {
        ...defaultQuizSettings,
        passMark: final ? 75 : 70,
        attempts: final ? 1 : 2,
        timeLimitMin: final ? lesson.durationMin : undefined,
        shuffleQuestions: final,
      };
      return {
        id,
        courseId: course.id,
        chapterId: chapter.id,
        lessonId,
        title: lesson.title,
        instructions: final
          ? `This is the final assessment for ${course.title}. You have one attempt and ${lesson.durationMin} minutes. Answer every question — unanswered questions score zero.`
          : `A short check on “${chapter.title}”. You can take it twice; your higher score counts.`,
        status: course.status === 'draft' ? 'draft' : 'published',
        questions: LESSON_TOPICS[lessonId].flatMap((topic) => build(topic, id)),
        settings,
        createdAt: course.createdAt,
        updatedAt: lesson.updatedAt,
      };
    }
  }
  return null;
}

export const quizzes: Quiz[] = [
  ...Object.keys(LESSON_TOPICS)
    .map(quizForLesson)
    .filter((q): q is Quiz => q !== null),
  {
    id: 'quiz-planets-check',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    title: 'Chapter 2 check: The Nine Planets',
    instructions: 'Six questions on the Navagraha — significations, dignities and rulership. Two attempts.',
    status: 'draft',
    questions: build('planets', 'quiz-planets-check'),
    settings: { ...defaultQuizSettings },
    createdAt: '2026-09-08T10:00:00+05:30',
    updatedAt: '2026-09-14T18:20:00+05:30',
  },
  {
    id: 'quiz-nakshatra-drill',
    courseId: 'nakshatra-depth',
    chapterId: 'nakshatra-depth-c1',
    title: 'Nakshatra lords: timed drill',
    instructions: 'Name the ruling graha of each nakshatra as quickly as you can. Fifteen minutes.',
    status: 'draft',
    questions: build('nakshatra', 'quiz-nakshatra-drill').slice(0, 3),
    settings: { ...defaultQuizSettings, timeLimitMin: 15, shuffleQuestions: true, attempts: 3 },
    createdAt: '2026-09-10T10:00:00+05:30',
    updatedAt: '2026-09-12T09:40:00+05:30',
  },
  {
    id: 'quiz-muhurta-practice',
    courseId: 'muhurta',
    chapterId: 'muhurta-c2',
    title: 'Lagna shuddhi practice set',
    instructions: '',
    status: 'draft',
    questions: [],
    settings: { ...defaultQuizSettings },
    createdAt: '2026-09-15T09:00:00+05:30',
    updatedAt: '2026-09-15T09:00:00+05:30',
  },
];
