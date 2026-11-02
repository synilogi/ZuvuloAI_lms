/* The demo academy's content — levels, categories, six courses with curriculum, instructors, students
 * with a year of enrolments, progress, quizzes, assignments, certificates, live classes, settings and
 * notifications — created inside ONE academy, given by id. It only creates rows: it never reads or
 * changes another academy, and never deletes. `prisma/seed.ts` (development) calls it for academy #1
 * after clearing it; `scripts/seed-demo-academy.ts` calls it for a new academy, safe on production. */
import bcrypt from 'bcryptjs';

import { asPlatform, forTenant } from '../src/lib/db.js';

export interface DemoAcademyOptions {
  tenantId: string;
  /** Shown in settings, certificates and the sender name. */
  academyName: string;
  /** Every login's address is `<name>@<emailDomain>`. Emails are unique across the platform. */
  emailDomain: string;
  /** One password for every demo login. */
  password: string;
  /** The seeded certificates' credential ids, unique across the platform: `<prefix>-00142`. */
  credentialPrefix: string;
  /** The academy's own prefix for certificates it issues from now on (settings), e.g. `SA`. */
  settingsCredentialPrefix: string;
  log?: (...args: unknown[]) => void;
}

export interface DemoAcademyLogins {
  admin: string;
  instructors: string[];
  students: string[];
}

export async function seedDemoAcademyContent(opts: DemoAcademyOptions): Promise<DemoAcademyLogins> {
  const { tenantId, academyName, credentialPrefix, settingsCredentialPrefix } = opts;
  const log = opts.log ?? (() => undefined);
  const T = { tenantId };
  const db = forTenant(tenantId);
  const platform = asPlatform('the demo seed fills one academy');
  const email = (name: string) => `${name}@${opts.emailDomain}`;
  const passwordHash = bcrypt.hashSync(opts.password, 10);
  try {
    log('Levels & ranks...');
    const [beginner, intermediate, advanced] = await Promise.all([
      db.level.create({ data: { ...T, name: 'Beginner', order: 1, summary: 'Building the basics' } }),
      db.level.create({ data: { ...T, name: 'Intermediate', order: 2, summary: 'Board and exam-level practice' } }),
      db.level.create({ data: { ...T, name: 'Advanced', order: 3, summary: 'Competitive exam depth' } }),
    ]);

    const ranks = await Promise.all([
      db.rank.create({ data: { ...T, title: 'Rank I · Beginner', order: 1, descriptor: 'Just getting started.', criteriaJson: '[]' } }),
      db.rank.create({
        data: {
          ...T,
          title: 'Rank II · Intermediate',
          order: 2,
          descriptor: 'Solving full-length papers.',
          criteriaJson: JSON.stringify([{ id: 'courses', label: 'Courses completed', current: 0, required: 2 }]),
        },
      }),
      db.rank.create({
        data: {
          ...T,
          title: 'Rank III · Advanced',
          order: 3,
          descriptor: 'Exam-ready across subjects.',
          criteriaJson: JSON.stringify([{ id: 'courses', label: 'Courses completed', current: 0, required: 4 }]),
        },
      }),
    ]);

    log('Categories...');
    const catFoundations = await db.category.create({
      data: {
        ...T,
        name: 'School Essentials',
        description: 'Maths foundations for classes 6–10.',
        order: 1,
        status: 'active',
        glyph: 'sun',
        levels: { create: [{ ...T, levelId: beginner.id }] },
      },
    });
    const catPredictive = await db.category.create({
      data: {
        ...T,
        name: 'Exam Aptitude',
        description: 'Logical reasoning and timed practice for SSC and state exams.',
        order: 2,
        status: 'active',
        glyph: 'orbits',
        levels: { create: [{ ...T, levelId: intermediate.id }] },
      },
    });
    const catSpecialised = await db.category.create({
      data: {
        ...T,
        name: 'State Exam Specials',
        description: 'RPSC, REET and Rajasthan-focused preparation.',
        order: 3,
        status: 'active',
        glyph: 'houses',
        levels: { create: [{ ...T, levelId: advanced.id }] },
      },
    });

    log('Instructors + their user accounts...');
    const meenakshi = await db.instructor.create({
      data: {
        ...T,
        name: 'Dr. Meenakshi Iyer',
        joinedAt: new Date(Date.now() - 780 * 86_400_000),
        title: 'Senior Mathematics Teacher',
        yearsTeaching: 14,
        email: email('meenakshi'),
        bio: 'Twenty years in the classroom and fourteen teaching school mathematics, from first integers to board-exam algebra.',
        expertiseJson: JSON.stringify(['Number system', 'Algebra', 'Board exam preparation']),
        status: 'active',
        city: 'Chennai',
        languagesJson: JSON.stringify(['English', 'Tamil']),
      },
    });
    const vinod = await db.instructor.create({
      data: {
        ...T,
        name: 'Acharya Vinod Shastri',
        joinedAt: new Date(Date.now() - 520 * 86_400_000),
        title: 'Reasoning & Aptitude Mentor',
        yearsTeaching: 20,
        email: email('vinod'),
        bio: 'Has coached SSC and state-exam aspirants in reasoning and aptitude for two decades, with a focus on speed and accuracy.',
        expertiseJson: JSON.stringify(['Logical reasoning', 'Quantitative aptitude', 'Rajasthan economy']),
        status: 'active',
        city: 'Varanasi',
        languagesJson: JSON.stringify(['English', 'Hindi']),
      },
    });
    const sanjay = await db.instructor.create({
      data: {
        ...T,
        name: 'Sanjay Rathore',
        joinedAt: new Date(Date.now() - 240 * 86_400_000),
        title: 'RPSC & REET Mentor',
        yearsTeaching: 11,
        email: email('sanjay'),
        bio: 'Prepares advanced aspirants for RPSC and REET, with a focus on teaching pedagogy and mains answer writing.',
        expertiseJson: JSON.stringify(['REET pedagogy', 'Answer writing', 'Rajasthan GK']),
        status: 'active',
        city: 'Jaipur',
        languagesJson: JSON.stringify(['English', 'Hindi']),
      },
    });

    log('Users: admin, instructor logins, students...');
    const admin = await db.user.create({
      data: { ...T, name: 'Kavita Menon', email: email('admin'), passwordHash: passwordHash, role: 'admin', descriptor: 'Platform admin' },
    });
    await platform.tenant.update({ where: { id: tenantId }, data: { ownerUserId: admin.id } });
    await db.user.create({
      data: {
        ...T,
        name: meenakshi.name,
        email: meenakshi.email,
        passwordHash: passwordHash,
        role: 'instructor',
        descriptor: meenakshi.title,
        instructorId: meenakshi.id,
      },
    });
    await db.user.create({
      data: { ...T, name: vinod.name, email: vinod.email, passwordHash: passwordHash, role: 'instructor', descriptor: vinod.title, instructorId: vinod.id },
    });

    const studentDefs = [
      { name: 'Ananya Rao', email: email('ananya'), city: 'Bengaluru' },
      { name: 'Rohit Sharma', email: email('rohit'), city: 'Pune' },
      { name: 'Priya Nair', email: email('priya'), city: 'Kochi' },
      { name: 'Karan Mehta', email: email('karan'), city: 'Ahmedabad' },
      { name: 'Sneha Iyer', email: email('sneha'), city: 'Chennai' },
      { name: 'Arjun Das', email: email('arjun'), city: 'Kolkata' },
      { name: 'Meera Pillai', email: email('meera'), city: 'Thiruvananthapuram' },
      { name: 'Vikram Singh', email: email('vikram'), city: 'Jaipur' },
    ];
    const students = [];
    for (let i = 0; i < studentDefs.length; i++) {
      const d = studentDefs[i];
      const daysAgo = 20 + i * 15;
      const user = await db.user.create({
        data: {
          ...T,
          name: d.name,
          email: d.email,
          passwordHash: passwordHash,
          role: 'student',
          descriptor: 'Beginner · Rank I',
          student: {
            create: {
              ...T,
              city: d.city,
              joinedAt: new Date(Date.now() - daysAgo * 86_400_000),
              lastActiveAt: new Date(Date.now() - (i % 3) * 86_400_000),
              rankId: ranks[i % ranks.length].id,
            },
          },
        },
        include: { student: true },
      });
      students.push(user.student!);
    }
    const [ananya, rohit, priya, karan, sneha, arjun, meera, vikram] = students;

    log('Courses with curriculum...');
    async function makeCourse(opts: {
      slug: string;
      title: string;
      subtitle: string;
      description: string;
      levelId: string;
      categoryId: string;
      coverMotif: string;
      instructorIds: string[];
      format?: string;
      price: number;
      /** Free unless said otherwise: the demo learners join these courses themselves. */
      pricing?: 'free' | 'paid';
      chapters: {
        title: string;
        summary: string;
        objective: string;
        lessons: { title: string; type: string; durationMin: number; description?: string; content?: object }[];
      }[];
      outcomes: string[];
      tags: string[];
    }) {
      const course = await db.course.create({
        data: {
          ...T,
          slug: opts.slug,
          title: opts.title,
          subtitle: opts.subtitle,
          description: opts.description,
          levelId: opts.levelId,
          categoryId: opts.categoryId,
          format: opts.format ?? 'self-paced',
          language: 'en-IN',
          coverMotif: opts.coverMotif,
          liveSessions: 1,
          estimatedWeeks: opts.chapters.length * 2,
          certificateTitle: `Certificate in ${opts.title}`,
          pricing: opts.pricing ?? 'free',
          priceAmount: opts.pricing === 'paid' ? opts.price : null,
          status: 'published',
          visibility: 'public',
          publishedAt: new Date(Date.now() - 60 * 86_400_000),
          outcomesJson: JSON.stringify(opts.outcomes),
          tagsJson: JSON.stringify(opts.tags),
          rating: 4.6 + Math.random() * 0.3,
          ratingCount: 40 + Math.floor(Math.random() * 400),
          instructors: { create: opts.instructorIds.map((instructorId) => ({ ...T, instructorId })) },
        },
      });
      for (let ci = 0; ci < opts.chapters.length; ci++) {
        const c = opts.chapters[ci];
        const chapter = await db.chapter.create({
          data: { ...T, courseId: course.id, title: c.title, summary: c.summary, objective: c.objective, status: 'published', position: ci },
        });
        for (let li = 0; li < c.lessons.length; li++) {
          const l = c.lessons[li];
          await db.lesson.create({
            data: {
              ...T,
              chapterId: chapter.id,
              courseId: course.id,
              title: l.title,
              type: l.type,
              durationMin: l.durationMin,
              status: 'published',
              isPreview: ci === 0 && li === 0,
              description: l.description,
              contentJson: JSON.stringify(l.content ?? {}),
              position: li,
            },
          });
        }
      }
      return db.course.findUniqueOrThrow({
        where: { id: course.id },
        include: { chapters: { orderBy: { position: 'asc' }, include: { lessons: { orderBy: { position: 'asc' } } } } },
      });
    }

    const foundations = await makeCourse({
      slug: 'maths-foundations',
      title: 'Maths Foundations for Classes 6–8',
      subtitle: 'Integers, fractions and decimals — गणित की नींव, one step at a time.',
      description:
        'A ground-up course in the number skills every later chapter depends on: integers and their signs, fractions, decimals and how to move between them, with a worked example and practice after each idea.',
      levelId: beginner.id,
      categoryId: catFoundations.id,
      coverMotif: 'houses',
      instructorIds: [meenakshi.id],
      price: 2999,
      outcomes: [
        'Add, subtract and multiply integers with confidence',
        'Convert between fractions, decimals and percentages',
        'Solve everyday word problems with fractions',
      ],
      tags: ['Beginner', 'Mathematics'],
      chapters: [
        {
          title: 'Integers',
          summary: 'Positive and negative numbers.',
          objective: 'By the end of this chapter, learners can add, subtract and multiply integers.',
          lessons: [
            {
              title: 'Introduction to integers | पूर्णांक',
              type: 'video',
              durationMin: 18,
              content: { video: { file: { name: 'integers-intro.mp4', sizeMb: 84 }, durationSec: 1080, captions: true, markers: [] } },
            },
            {
              title: 'The rules of signs',
              type: 'reading',
              durationMin: 12,
              content: {
                article: {
                  body: 'An integer is a whole number that can be positive, negative or zero. On the number line, numbers to the right of zero are positive and numbers to the left are negative; the further left a number sits, the smaller it is, so −7 is less than −2.\n\nWhen you multiply or divide two integers, the signs decide the sign of the answer: like signs give a positive result and unlike signs give a negative one. So (−3) × (−4) = 12, while (−3) × 4 = −12. For addition, picture moving along the number line: adding a negative number moves you to the left.',
                },
              },
            },
            { title: 'Chapter check', type: 'assessment', durationMin: 10 },
          ],
        },
        {
          title: 'Fractions and Decimals',
          summary: 'Parts of a whole, written two ways.',
          objective: 'By the end of this chapter, learners can convert between fractions, decimals and percentages.',
          lessons: [
            {
              title: 'Fractions on the number line',
              type: 'video',
              durationMin: 22,
              content: { video: { file: { name: 'fractions.mp4', sizeMb: 96 }, durationSec: 1320, captions: true, markers: [] } },
            },
            {
              title: 'Converting fractions and decimals | भिन्न और दशमलव',
              type: 'reading',
              durationMin: 15,
              content: {
                article: {
                  body: 'To turn a fraction into a decimal, divide the numerator by the denominator: 3/4 = 3 ÷ 4 = 0.75. To turn a decimal into a fraction, write it over the matching power of ten and simplify: 0.6 = 6/10 = 3/5.\n\nSome fractions never end: 1/3 = 0.333… repeats for ever. A fraction in its lowest terms gives a terminating decimal only when its denominator has no prime factors other than 2 and 5. A percentage is a fraction out of 100, so 0.75 is 75%.',
                },
              },
            },
            {
              title: 'Fraction practice set',
              type: 'practice',
              durationMin: 25,
              content: {
                article: {
                  body: 'Work through the ten questions on the practice sheet. For each one, write the fraction in its lowest terms, convert it to a decimal and a percentage, and show every step of your working.',
                },
              },
            },
            {
              title: 'Your first assignment: fractions at home',
              type: 'assignment',
              durationMin: 40,
              content: {
                assignment: {
                  brief:
                    'Find three places at home where fractions or decimals are used — a recipe, an electricity bill, a medicine label. For each one, write the quantity as a fraction, a decimal and a percentage, and explain in two sentences how you converted it.',
                  dueAfterDays: 7,
                  maxScore: 100,
                  submission: 'text',
                },
              },
            },
          ],
        },
      ],
    });

    const algebra = await makeCourse({
      slug: 'algebra-essentials',
      title: 'Algebra Essentials for Classes 9–10',
      subtitle: 'Expressions, identities and linear equations — बीजगणित made clear.',
      description:
        'A close study of the algebra that board exams lean on: building and simplifying expressions, using the standard identities, and turning word problems into linear equations you can solve.',
      levelId: intermediate.id,
      categoryId: catFoundations.id,
      coverMotif: 'nakshatra',
      instructorIds: [meenakshi.id],
      price: 3499,
      outcomes: ['Expand and factorise with the standard identities', 'Solve linear equations in one variable', 'Turn a word problem into an equation'],
      tags: ['Intermediate', 'Algebra'],
      chapters: [
        {
          title: 'Expressions and Identities',
          summary: 'The building blocks of algebra.',
          objective: 'By the end of this chapter, learners can expand and factorise using the standard identities.',
          lessons: [
            {
              title: 'Variables, terms and expressions',
              type: 'video',
              durationMin: 20,
              content: { video: { file: { name: 'expressions.mp4', sizeMb: 88 }, durationSec: 1200, captions: true, markers: [] } },
            },
            {
              title: 'Using the standard identities',
              type: 'reading',
              durationMin: 16,
              content: {
                article: {
                  body: 'Three identities do most of the work at this level: (a + b)² = a² + 2ab + b², (a − b)² = a² − 2ab + b², and (a + b)(a − b) = a² − b². An identity holds for every value of its variables, which is what lets you use it as a shortcut.\n\nThey work in both directions. Expanding (x + 5)² gives x² + 10x + 25, and seeing that 49 − y² is 7² − y² lets you factorise it at once as (7 + y)(7 − y). They speed up arithmetic too: 102² = (100 + 2)² = 10,000 + 400 + 4 = 10,404.',
                },
              },
            },
          ],
        },
        {
          title: 'Linear Equations',
          summary: 'Equations in one variable.',
          objective: 'By the end of this chapter, learners can form and solve a linear equation from a word problem.',
          lessons: [
            {
              title: 'Solving equations in one variable',
              type: 'video',
              durationMin: 19,
              content: { video: { file: { name: 'linear-equations.mp4', sizeMb: 90 }, durationSec: 1140, captions: true, markers: [] } },
            },
            {
              title: 'Word problems to equations',
              type: 'practice',
              durationMin: 20,
              content: {
                article: {
                  body: 'For each word problem on the sheet, name the unknown, write the equation the problem describes, solve it, and check your answer by putting it back into the original problem.',
                },
              },
            },
            { title: 'Algebra quiz', type: 'assessment', durationMin: 15 },
          ],
        },
      ],
    });

    const reasoning = await makeCourse({
      slug: 'logical-reasoning',
      title: 'Logical Reasoning Workout',
      subtitle: 'Series, analogies and puzzles for SSC and state exams | तर्कशक्ति अभ्यास.',
      description:
        'Build speed and accuracy on the reasoning questions that appear in almost every competitive exam: number and letter series, analogies and seating-arrangement puzzles, with timed practice throughout.',
      levelId: intermediate.id,
      categoryId: catPredictive.id,
      coverMotif: 'orbits',
      instructorIds: [vinod.id],
      price: 3999,
      outcomes: ['Find the rule behind a number or letter series', 'Solve analogy questions quickly', 'Work through a seating-arrangement puzzle clue by clue'],
      tags: ['Intermediate', 'Reasoning'],
      chapters: [
        {
          title: 'Series and Analogies',
          summary: 'Spotting the pattern.',
          objective: 'By the end of this chapter, learners can find the next term of a series and complete an analogy.',
          lessons: [
            {
              title: 'Number and letter series',
              type: 'video',
              durationMin: 24,
              content: { video: { file: { name: 'series.mp4', sizeMb: 102 }, durationSec: 1440, captions: true, markers: [] } },
            },
            {
              title: 'Cracking an analogy',
              type: 'reading',
              durationMin: 14,
              content: {
                article: {
                  body: 'An analogy question gives you one pair and asks you to complete a second pair that follows the same relationship. Before you look at the options, say the relationship in words: “a pen is used to write”, “8 is the cube of 2”.\n\nThen test that sentence on each option. If more than one fits, make the relationship more precise. Letter analogies often hide a fixed shift in alphabet positions, so write the position numbers (A = 1, B = 2 …) beside the letters when the pattern is not obvious.',
                },
              },
            },
          ],
        },
        {
          title: 'Puzzles and Arrangements',
          summary: 'Seating and ordering puzzles.',
          objective: 'By the end of this chapter, learners can solve a linear seating arrangement from its clues.',
          lessons: [
            {
              title: 'Seating arrangements',
              type: 'video',
              durationMin: 20,
              content: { video: { file: { name: 'seating.mp4', sizeMb: 91 }, durationSec: 1200, captions: true, markers: [] } },
            },
            {
              title: 'Puzzle-solving exercise',
              type: 'assignment',
              durationMin: 35,
              content: {
                assignment: {
                  brief:
                    'Solve the five seating-arrangement puzzles on the worksheet. For each one, write out the order you found and explain, clue by clue, how you reached it.',
                  dueAfterDays: 10,
                  maxScore: 100,
                  submission: 'text',
                },
              },
            },
          ],
        },
      ],
    });

    const rajEconomy = await makeCourse({
      slug: 'rajasthan-economy',
      title: 'Rajasthan Economy for RAS Mains',
      subtitle: 'राजस्थान की अर्थव्यवस्था · agriculture, minerals and energy.',
      description:
        'The economy of Rajasthan as the RAS mains syllabus treats it: agriculture and irrigation, mineral resources and the state’s fast-growing renewable-energy sector, with the facts examiners return to most often.',
      levelId: advanced.id,
      categoryId: catSpecialised.id,
      coverMotif: 'ecliptic',
      instructorIds: [vinod.id],
      price: 4999,
      outcomes: [
        'Explain the main crops and irrigation projects of Rajasthan',
        'Describe the state’s key mineral resources',
        'Discuss Rajasthan’s role in renewable energy',
      ],
      tags: ['Advanced', 'RAS'],
      chapters: [
        {
          title: 'Resources and Agriculture',
          summary: 'Land, water and minerals.',
          objective: 'By the end of this chapter, learners can describe Rajasthan’s main agricultural and mineral resources.',
          lessons: [
            {
              title: 'Crops and irrigation in Rajasthan',
              type: 'video',
              durationMin: 26,
              content: { video: { file: { name: 'agriculture.mp4', sizeMb: 110 }, durationSec: 1560, captions: true, markers: [] } },
            },
            {
              title: 'Minerals and energy | खनिज एवं ऊर्जा',
              type: 'reading',
              durationMin: 18,
              content: {
                article: {
                  body: 'Rajasthan is often called a museum of minerals for the range of deposits it holds. It is the country’s leading source of lead and zinc, mined at places such as Zawar near Udaipur, and the marble of Makrana has been quarried for centuries. Copper from the Khetri belt and large reserves of gypsum and limestone add to that base.\n\nThe open land and strong sunshine that make farming hard have also made the state a leader in solar power, and the Bhadla Solar Park in the Thar is among the largest in the world. When you answer a mains question on resources, link each resource to the industry it supports and the region where it is found.',
                },
              },
            },
          ],
        },
      ],
    });

    const reetPedagogy = await makeCourse({
      slug: 'reet-maths-pedagogy',
      title: 'REET Level 2: Mathematics Pedagogy',
      subtitle: 'गणित शिक्षण · how children learn maths, and how to teach it.',
      description:
        'The pedagogy section of REET Level 2 for the mathematics stream: the nature of mathematics, how children build mathematical ideas, and how to read a learner’s errors so your teaching responds to them.',
      levelId: advanced.id,
      categoryId: catSpecialised.id,
      coverMotif: 'orbits',
      instructorIds: [sanjay.id],
      price: 4999,
      outcomes: [
        'Explain the nature and aims of school mathematics',
        'Choose a suitable teaching method for a topic',
        'Diagnose common errors and plan remedial teaching',
      ],
      tags: ['Advanced', 'REET'],
      chapters: [
        {
          title: 'Teaching Mathematics',
          summary: 'Nature, methods and assessment.',
          objective: 'By the end of this chapter, learners can match a teaching method to a topic and diagnose a learner’s error.',
          lessons: [
            {
              title: 'The nature of mathematics',
              type: 'video',
              durationMin: 21,
              content: { video: { file: { name: 'nature-of-maths.mp4', sizeMb: 95 }, durationSec: 1260, captions: true, markers: [] } },
            },
            {
              title: 'Error analysis in the classroom',
              type: 'reading',
              durationMin: 17,
              content: {
                article: {
                  body: 'A wrong answer is information. When a learner writes 0.5 + 0.25 = 0.30, they are not guessing: they are adding the digits after the decimal point as if they were whole numbers. Naming the misconception, rather than simply marking the answer wrong, tells you what to teach again.\n\nREET questions on this topic usually describe a learner’s error and ask for the best response. Prefer the options that find the thinking behind the error and use concrete material or a fresh example over those that repeat the rule or set more of the same practice.',
                },
              },
            },
          ],
        },
      ],
    });

    const answerWriting = await makeCourse({
      slug: 'rpsc-answer-writing',
      title: 'RPSC Mains Answer Writing',
      subtitle: 'उत्तर लेखन · clear, structured answers within the word limit.',
      description:
        'Answer writing for the RPSC mains with Sanjay Rathore: reading what a question really asks, structuring an answer within its word limit, and using examples, maps and diagrams to earn marks.',
      levelId: advanced.id,
      categoryId: catSpecialised.id,
      coverMotif: 'houses',
      instructorIds: [sanjay.id],
      price: 3999,
      outcomes: ['Break a question down into what it asks', 'Structure an answer within its word limit', 'Support each point with an example or diagram'],
      tags: ['Advanced', 'RPSC'],
      chapters: [
        {
          title: 'Foundations of Answer Writing',
          summary: 'Reading the question and planning the answer.',
          objective: 'By the end of this chapter, learners can plan and write a structured mains answer.',
          lessons: [
            {
              title: 'What examiners look for',
              type: 'video',
              durationMin: 18,
              content: { video: { file: { name: 'examiners.mp4', sizeMb: 80 }, durationSec: 1080, captions: true, markers: [] } },
            },
            {
              title: 'Structuring a 50-word answer',
              type: 'video',
              durationMin: 22,
              content: { video: { file: { name: 'answer-structure.mp4', sizeMb: 94 }, durationSec: 1320, captions: true, markers: [] } },
            },
            {
              title: 'Directive words and examples',
              type: 'reading',
              durationMin: 16,
              content: {
                article: {
                  body: 'Every mains question carries a directive word — describe, explain, examine, discuss — and each asks for something different. “Describe” wants the features of a thing; “explain” wants causes and reasons; “examine” and “discuss” want more than one side, ending in a balanced view.\n\nWithin a short word limit, an answer earns its marks with a direct opening line, two or three well-chosen points and one concrete example from Rajasthan or India. A small sketch map or flowchart can carry what would take thirty words to write out.',
                },
              },
            },
          ],
        },
      ],
    });

    const courses = [foundations, algebra, reasoning, rajEconomy, reetPedagogy, answerWriting];

    log('Certificate templates...');
    const classic = await db.certificateTemplate.create({
      data: {
        ...T,
        name: 'Classic seal',
        style: 'classic',
        accent: 'emerald',
        heading: 'Certificate of Completion',
        statement: 'has completed the course of study in',
        signatoriesJson: JSON.stringify([
          { name: 'Dr. Meenakshi Iyer', title: 'Director of Studies' },
          { name: 'Kavita Menon', title: 'Academy Director' },
        ]),
        showScore: true,
        showHours: true,
        isDefault: true,
      },
    });
    await db.certificateTemplate.create({
      data: {
        ...T,
        name: 'Cohort achievement',
        style: 'modern',
        accent: 'saffron',
        heading: 'Certificate of Achievement',
        statement: 'has completed the cohort programme and final project in',
        signatoriesJson: JSON.stringify([{ name: 'Sanjay Rathore', title: 'Programme Lead' }]),
        showScore: true,
        showHours: false,
      },
    });
    await db.certificateTemplate.create({
      data: {
        ...T,
        name: 'Foundation courses',
        style: 'minimal',
        accent: 'indigo',
        heading: 'Certificate of Completion',
        statement: 'has completed',
        signatoriesJson: JSON.stringify([{ name: 'Kavita Menon', title: 'Academy Director' }]),
        showScore: false,
        showHours: true,
      },
    });

    log('Enrollments, progress, quizzes, assignments, certificates for the demo students...');
    async function enrollAndProgress(
      student: { id: string },
      course: typeof foundations,
      opts: { progress: number; status?: string; completedLessons?: number },
    ) {
      const allLessons = course.chapters.flatMap((c) => c.lessons);
      const enrolledAt = new Date(Date.now() - (10 + Math.random() * 40) * 86_400_000);
      await db.enrollment.create({
        data: {
          ...T,
          studentId: student.id,
          courseId: course.id,
          enrolledAt,
          status: opts.status ?? (opts.progress >= 100 ? 'completed' : 'active'),
          progress: opts.progress,
          lastActiveAt: new Date(Date.now() - Math.random() * 5 * 86_400_000),
          completedAt: opts.progress >= 100 ? new Date() : null,
          source: 'self',
        },
      });
      await db.course.update({ where: { id: course.id }, data: { enrolledCount: { increment: 1 } } });
      const toComplete = opts.completedLessons ?? Math.round((allLessons.length * opts.progress) / 100);
      for (let i = 0; i < toComplete && i < allLessons.length; i++) {
        await db.lessonProgress.create({
          data: {
            ...T,
            studentId: student.id,
            lessonId: allLessons[i].id,
            state: 'completed',
            fraction: 1,
            completedAt: new Date(Date.now() - (toComplete - i) * 2 * 86_400_000),
          },
        });
      }
      if (toComplete < allLessons.length) {
        await db.lessonProgress.create({
          data: { ...T, studentId: student.id, lessonId: allLessons[toComplete].id, state: 'in-progress', fraction: 0.4, positionSec: 300 },
        });
      }
    }

    await enrollAndProgress(ananya, foundations, { progress: 38 });
    await enrollAndProgress(ananya, algebra, { progress: 100, status: 'completed' });
    await enrollAndProgress(ananya, reasoning, { progress: 15 });
    await enrollAndProgress(rohit, foundations, { progress: 62 });
    await enrollAndProgress(rohit, reasoning, { progress: 100, status: 'completed' });
    await enrollAndProgress(priya, foundations, { progress: 100, status: 'completed' });
    await enrollAndProgress(priya, rajEconomy, { progress: 22 });
    await enrollAndProgress(karan, foundations, { progress: 8 });
    await enrollAndProgress(sneha, algebra, { progress: 71 });
    await enrollAndProgress(arjun, reetPedagogy, { progress: 45 });
    await enrollAndProgress(meera, answerWriting, { progress: 30 });
    await enrollAndProgress(vikram, reasoning, { progress: 88 });
    await enrollAndProgress(vikram, foundations, { progress: 100, status: 'completed' });

    log('Quizzes for the assessment lessons...');
    for (const course of courses) {
      for (const chapter of course.chapters) {
        for (const lesson of chapter.lessons) {
          if (lesson.type !== 'assessment') continue;
          const questions = [
            {
              id: 'q1',
              type: 'single',
              prompt: 'What is (−3) × (−4)?',
              options: [
                { id: 'a', text: '12' },
                { id: 'b', text: '−12' },
                { id: 'c', text: '−7' },
                { id: 'd', text: '1' },
              ],
              correct: ['a'],
              acceptedAnswers: [],
              points: 10,
              required: true,
            },
            {
              id: 'q2',
              type: 'true-false',
              prompt: 'Every fraction can be written as a decimal that ends.',
              options: [
                { id: 'true', text: 'True' },
                { id: 'false', text: 'False' },
              ],
              correct: ['false'],
              acceptedAnswers: [],
              points: 10,
              required: true,
            },
            {
              id: 'q3',
              type: 'short',
              prompt: 'Write 3/4 as a percentage.',
              options: [],
              correct: [],
              acceptedAnswers: ['75%', '75', '75 %', '75 percent', '75 per cent'],
              points: 10,
              required: true,
            },
          ];
          await db.quiz.create({
            data: {
              ...T,
              courseId: course.id,
              chapterId: chapter.id,
              lessonId: lesson.id,
              title: `${chapter.title}: check your understanding`,
              instructions: 'Answer every question. You can retake this quiz.',
              status: 'published',
              questionsJson: JSON.stringify(questions),
              settingsJson: JSON.stringify({ passMark: 70, attempts: 3, shuffleQuestions: false, shuffleOptions: true, showResults: 'score-and-answers' }),
            },
          });
        }
      }
    }

    const foundationsQuiz = await db.quiz.findFirst({ where: { courseId: foundations.id } });
    if (foundationsQuiz) {
      await db.quizAttempt.create({
        data: { ...T, quizId: foundationsQuiz.id, studentId: ananya.id, percent: 83, passed: true, answersJson: '{}', resultJson: '{}' },
      });
      await db.quizAttempt.create({
        data: { ...T, quizId: foundationsQuiz.id, studentId: rohit.id, percent: 60, passed: false, answersJson: '{}', resultJson: '{}' },
      });
      await db.quizAttempt.create({
        data: { ...T, quizId: foundationsQuiz.id, studentId: priya.id, percent: 93, passed: true, answersJson: '{}', resultJson: '{}' },
      });
    }

    log('Assignments and a submission to review...');
    for (const course of courses) {
      for (const chapter of course.chapters) {
        for (const lesson of chapter.lessons) {
          if (lesson.type !== 'assignment') continue;
          const content = JSON.parse(lesson.contentJson || '{}') as {
            assignment?: { brief: string; dueAfterDays: number; maxScore: number; submission: string };
          };
          const a = content.assignment;
          if (!a) continue;
          await db.courseAssignment.create({
            data: {
              ...T,
              courseId: course.id,
              chapterId: chapter.id,
              lessonId: lesson.id,
              title: lesson.title,
              instructions: a.brief,
              format: a.submission,
              dueJson: JSON.stringify({ kind: 'relative', days: a.dueAfterDays }),
              acceptsLate: true,
              latePenalty: 10,
              rubricJson: '[]',
              maxScore: a.maxScore,
              passMark: 60,
              status: 'published',
            },
          });
        }
      }
    }
    const foundationsAssignment = await db.courseAssignment.findFirst({ where: { courseId: foundations.id } });
    if (foundationsAssignment) {
      await db.submission.create({
        data: {
          ...T,
          assignmentId: foundationsAssignment.id,
          studentId: ananya.id,
          attempt: 1,
          submittedAt: new Date(Date.now() - 2 * 86_400_000),
          late: false,
          text: 'Recipe: 3/4 cup of milk = 0.75 = 75%. Electricity bill: 0.5 units… (sample submission)',
          filesJson: '[]',
          reviewStatus: 'waiting',
        },
      });
      await db.submission.create({
        data: {
          ...T,
          assignmentId: foundationsAssignment.id,
          studentId: priya.id,
          attempt: 1,
          submittedAt: new Date(Date.now() - 20 * 86_400_000),
          late: false,
          text: 'Three examples from home — a recipe, a bill and a medicine label — each written as a fraction, a decimal and a percentage, with the division shown.',
          filesJson: '[]',
          reviewStatus: 'graded',
          score: 88,
          feedback: 'Clear and well-organised — good use of the number line to check each conversion.',
          reviewUpdatedAt: new Date(Date.now() - 18 * 86_400_000),
        },
      });
    }

    log('Issued certificates...');
    const algebraCourse = algebra;
    await db.issuedCertificate.create({
      data: {
        ...T,
        credentialId: `${credentialPrefix}-00142`,
        studentId: ananya.id,
        courseId: algebraCourse.id,
        title: `Certificate in ${algebraCourse.title}`,
        templateId: classic.id,
        status: 'issued',
        completedAt: new Date(Date.now() - 30 * 86_400_000),
        issuedAt: new Date(Date.now() - 29 * 86_400_000),
        finalScore: 91,
        hours: 6,
        verifications: 3,
      },
    });
    await db.issuedCertificate.create({
      data: {
        ...T,
        credentialId: `${credentialPrefix}-00198`,
        studentId: priya.id,
        courseId: foundations.id,
        title: `Certificate in ${foundations.title}`,
        templateId: classic.id,
        status: 'issued',
        completedAt: new Date(Date.now() - 15 * 86_400_000),
        issuedAt: new Date(Date.now() - 14 * 86_400_000),
        finalScore: 88,
        hours: 9,
        verifications: 1,
      },
    });
    await db.issuedCertificate.create({
      data: {
        ...T,
        credentialId: `${credentialPrefix}-00231`,
        studentId: vikram.id,
        courseId: reasoning.id,
        title: `Certificate in ${reasoning.title}`,
        templateId: classic.id,
        status: 'pending',
        completedAt: new Date(Date.now() - 1 * 86_400_000),
        finalScore: 79,
        hours: 8,
        verifications: 0,
      },
    });

    log('Live classes...');
    const now = Date.now();
    await db.liveClass.create({
      data: {
        ...T,
        courseId: foundations.id,
        title: 'Fractions in everyday problems',
        instructorId: meenakshi.id,
        startsAt: new Date(now + 2 * 86_400_000),
        durationMin: 60,
        capacity: 40,
        description: 'A live problem-solving session on fractions and decimals, using examples from shopping, cooking and household bills.',
        agendaJson: JSON.stringify([
          { title: 'Recap of the conversion rules', minutes: 10 },
          { title: 'Live problem solving', minutes: 40 },
          { title: 'Q&A', minutes: 10 },
        ]),
        visibility: 'enrolled',
        meetingJson: JSON.stringify({ kind: 'room' }),
        remindersJson: JSON.stringify([1440, 60]),
      },
    });
    await db.liveClass.create({
      data: {
        ...T,
        courseId: reasoning.id,
        title: 'Reasoning doubt-clearing hours',
        instructorId: vinod.id,
        startsAt: new Date(now - 5 * 86_400_000),
        durationMin: 45,
        capacity: 30,
        description: 'Open office hours for reasoning doubts — bring the puzzles that stumped you.',
        agendaJson: '[]',
        visibility: 'enrolled',
        meetingJson: JSON.stringify({ kind: 'room' }),
        remindersJson: '[]',
        recordingJson: JSON.stringify({ durationMin: 42, availableUntil: new Date(now + 25 * 86_400_000).toISOString() }),
      },
    });

    /* A year of history. The demo learners above show the product as it is used today; reports also
     * need a past to compare today against — a previous period, monthly cohorts, courses finished long
     * enough ago to judge a completion rate, and live classes that have actually been attended. These
     * alumni supply it, all drawn from one fixed seed so every figure is stable between runs. */
    log('Past year of alumni, enrolments, coursework and attendance...');
    {
      let state = 20260915;
      /** Deterministic 0–1. */
      const rnd = () => {
        state = (state * 1664525 + 1013904223) % 4294967296;
        return state / 4294967296;
      };
      const pick = <T>(list: T[]): T => list[Math.floor(rnd() * list.length)];
      const between = (min: number, max: number) => min + rnd() * (max - min);
      const ago = (days: number) => new Date(now - days * 86_400_000);

      const firstNames = [
        'Aditi',
        'Nikhil',
        'Shreya',
        'Manish',
        'Divya',
        'Rahul',
        'Kavya',
        'Suresh',
        'Anjali',
        'Prakash',
        'Ritu',
        'Gaurav',
        'Lakshmi',
        'Imran',
        'Tara',
        'Deepak',
        'Nandini',
        'Vivek',
      ];
      const lastNames = ['Kulkarni', 'Banerjee', 'Reddy', 'Joshi', 'Chauhan', 'Menon', 'Sinha', 'Patel', 'Ghosh', 'Rao'];
      const cities = ['Mumbai', 'Delhi', 'Hyderabad', 'Indore', 'Nagpur', 'Lucknow', 'Surat', 'Bhopal', 'Patna', 'Coimbatore'];
      const sources = ['self', 'self', 'self', 'cohort', 'admin', 'scholarship'];

      const publishedCourses = [foundations, algebra, reasoning, rajEconomy, reetPedagogy, answerWriting];
      const quizzesByCourse = new Map<string, { id: string }[]>();
      const assignmentsByCourse = new Map<string, { id: string; maxScore: number; passMark: number }[]>();
      const teachersByCourse = new Map<string, string[]>();
      for (const course of publishedCourses) {
        quizzesByCourse.set(course.id, await db.quiz.findMany({ where: { courseId: course.id, status: 'published' }, select: { id: true } }));
        assignmentsByCourse.set(
          course.id,
          await db.courseAssignment.findMany({
            where: { courseId: course.id, status: { not: 'draft' } },
            select: { id: true, maxScore: true, passMark: true },
          }),
        );
        teachersByCourse.set(
          course.id,
          (await db.courseInstructor.findMany({ where: { courseId: course.id }, select: { instructorId: true } })).map((r) => r.instructorId),
        );
      }

      let alumniCount = 0;
      for (let i = 0; i < 36; i++) {
        const name = `${firstNames[i % firstNames.length]} ${lastNames[Math.floor(i / 3) % lastNames.length]}`;
        // Joined between two months and thirteen months ago.
        const joinedDaysAgo = Math.round(between(60, 400));
        const user = await db.user.create({
          data: {
            ...T,
            name,
            email: email(`alum${i + 1}`),
            passwordHash: passwordHash,
            role: 'student',
            descriptor: 'Beginner · Rank I',
            student: {
              create: { ...T, city: pick(cities), joinedAt: ago(joinedDaysAgo), lastActiveAt: ago(joinedDaysAgo), rankId: ranks[i % ranks.length].id },
            },
          },
          include: { student: true },
        });
        const student = user.student!;
        let lastSeen = ago(joinedDaysAgo).getTime();

        // One or two courses each, always starting after they joined.
        const wanted = rnd() < 0.35 ? 2 : 1;
        const chosen: typeof publishedCourses = [];
        while (chosen.length < wanted) {
          const course = pick(publishedCourses);
          if (!chosen.includes(course)) chosen.push(course);
        }

        for (const course of chosen) {
          const enrolledDaysAgo = Math.round(between(2, joinedDaysAgo));
          const enrolledAt = ago(enrolledDaysAgo);
          const lessons = course.chapters.flatMap((c) => c.lessons);
          // Older intakes finished more often; recent ones are still working through.
          const finished = rnd() < (enrolledDaysAgo > 120 ? 0.62 : enrolledDaysAgo > 60 ? 0.42 : 0.18);
          const takesDays = Math.max(1, Math.min(enrolledDaysAgo - 1, Math.round(between(18, 80))));
          const completedAt = finished ? ago(enrolledDaysAgo - takesDays) : null;
          const doneCount = finished ? lessons.length : Math.max(0, Math.round(lessons.length * between(0, 0.8)));
          const progress = finished ? 100 : lessons.length ? Math.round((doneCount / lessons.length) * 100) : 0;
          // Some go quiet, so at-risk and inactive learners are real rather than assumed.
          const lastActiveAt = completedAt ?? ago(Math.max(1, enrolledDaysAgo - Math.round(between(1, takesDays))));
          lastSeen = Math.max(lastSeen, lastActiveAt.getTime());

          await db.enrollment.create({
            data: {
              ...T,
              studentId: student.id,
              courseId: course.id,
              enrolledAt,
              status: finished ? 'completed' : 'active',
              progress,
              source: pick(sources),
              lastActiveAt,
              completedAt,
            },
          });
          await db.course.update({ where: { id: course.id }, data: { enrolledCount: { increment: 1 } } });

          // Lesson progress is dated across the study span, so progress can be placed at any past moment.
          const span = Math.max(1, completedAt ? takesDays : Math.round(between(2, Math.max(3, enrolledDaysAgo - 1))));
          const dayOfLesson = (n: number) => Math.max(1, Math.round(enrolledDaysAgo - ((n + 1) / Math.max(1, doneCount)) * span));
          if (doneCount > 0) {
            await db.lessonProgress.createMany({
              data: lessons.slice(0, doneCount).map((lesson, n) => ({
                ...T,
                studentId: student.id,
                lessonId: lesson.id,
                state: 'completed',
                fraction: 1,
                completedAt: ago(dayOfLesson(n)),
                lastAccessedAt: ago(dayOfLesson(n)),
              })),
            });
          }
          if (doneCount < lessons.length && rnd() < 0.6) {
            await db.lessonProgress.create({
              data: {
                ...T,
                studentId: student.id,
                lessonId: lessons[doneCount].id,
                state: 'in-progress',
                fraction: Math.round(between(0.2, 0.8) * 10) / 10,
                positionSec: 240,
                lastAccessedAt: lastActiveAt,
              },
            });
          }

          // Attempts and hand-ins land inside the study span, with real scores and review turnaround.
          for (const quiz of quizzesByCourse.get(course.id) ?? []) {
            if (rnd() > (finished ? 0.85 : 0.45)) continue;
            const percent = Math.round(between(40, 100));
            await db.quizAttempt.create({
              data: {
                ...T,
                quizId: quiz.id,
                studentId: student.id,
                percent,
                passed: percent >= 70,
                answersJson: '{}',
                resultJson: '{}',
                durationSec: Math.round(between(240, 900)),
                createdAt: ago(Math.max(1, Math.round(enrolledDaysAgo - between(1, span)))),
              },
            });
          }
          for (const assignment of assignmentsByCourse.get(course.id) ?? []) {
            if (rnd() > (finished ? 0.7 : 0.3)) continue;
            const submittedDaysAgo = Math.max(2, Math.round(enrolledDaysAgo - between(1, span)));
            const score = Math.round(between(assignment.passMark - 20, assignment.maxScore));
            await db.submission.create({
              data: {
                ...T,
                assignmentId: assignment.id,
                studentId: student.id,
                attempt: 1,
                submittedAt: ago(submittedDaysAgo),
                late: rnd() < 0.18,
                text: 'Worked answers to every question, with each step of the reasoning shown.',
                filesJson: '[]',
                reviewStatus: 'graded',
                reviewerId: pick(teachersByCourse.get(course.id)?.length ? teachersByCourse.get(course.id)! : [meenakshi.id]),
                scoresJson: '{}',
                score: Math.max(0, Math.min(assignment.maxScore, score)),
                feedback: 'Sound reasoning. Show the final step of each answer before the next hand-in.',
                reviewUpdatedAt: new Date(ago(submittedDaysAgo).getTime() + between(3, 96) * 3_600_000),
              },
            });
          }
        }

        await db.student.update({ where: { id: student.id }, data: { lastActiveAt: new Date(lastSeen) } });
        alumniCount += 1;
      }

      // Live classes that have already run, with attendance taken.
      const pastClasses = [
        { course: foundations, instructor: meenakshi, title: 'Integers: worked examples', daysAgo: 24 },
        { course: foundations, instructor: meenakshi, title: 'Fractions in practice: a live class', daysAgo: 52 },
        { course: algebra, instructor: meenakshi, title: 'Linear equations: your questions answered', daysAgo: 81 },
        { course: reasoning, instructor: vinod, title: 'Series and analogies: timed practice', daysAgo: 110 },
        { course: reetPedagogy, instructor: vinod, title: 'Maths pedagogy: open office hours', daysAgo: 146 },
        { course: answerWriting, instructor: sanjay, title: 'Answer writing: a model answer, live', daysAgo: 173 },
      ];
      for (const past of pastClasses) {
        const liveClass = await db.liveClass.create({
          data: {
            ...T,
            courseId: past.course.id,
            title: past.title,
            instructorId: past.instructor.id,
            startsAt: ago(past.daysAgo),
            durationMin: 60,
            capacity: 40,
            description: 'A session from the academy archive, with the recording kept for enrolled learners.',
            agendaJson: '[]',
            visibility: 'enrolled',
            meetingJson: JSON.stringify({ kind: 'room' }),
            remindersJson: '[]',
            remindersSentJson: '[]',
            recordingJson: JSON.stringify({ durationMin: 58, availableUntil: new Date(now + 90 * 86_400_000).toISOString() }),
          },
        });
        // Whoever was already enrolled when it ran could have been there, and most of them turned up.
        const eligible = await db.enrollment.findMany({
          where: { courseId: past.course.id, enrolledAt: { lte: ago(past.daysAgo) } },
          select: { studentId: true },
          take: 24,
        });
        if (eligible.length === 0) continue;
        await db.liveRegistration.createMany({
          data: eligible.map((e) => ({ ...T, liveClassId: liveClass.id, studentId: e.studentId, registeredAt: ago(past.daysAgo + 2), attended: rnd() < 0.78 })),
        });
      }
      log(`  ${alumniCount} alumni and ${pastClasses.length} past live classes`);
    }

    log('Academy settings...');
    const nowIso = new Date().toISOString();
    await db.settings.create({
      data: {
        ...T,
        generalJson: JSON.stringify({
          academyName,
          lmsLabel: 'Learning',
          supportEmail: 'synilogicteam@gmail.com',
          language: 'en-IN',
          defaultVisibility: 'public',
          enrollment: 'open',
          accessMonths: null,
          lessonDefaults: { durationMin: 15, completion: 'time', allowComments: true, allowDownloads: true, previewFirstLesson: true },
        }),
        coursesJson: JSON.stringify({
          defaultFormat: 'self-paced',
          release: 'sequential',
          requireReview: true,
          maxInstructors: 3,
          defaultPrice: 2999,
          showRatings: true,
          minRatings: 5,
          showEnrolmentCount: true,
          archiveInactiveMonths: 12,
        }),
        learningJson: JSON.stringify({
          completionThreshold: 90,
          courseCompletion: 'all-lessons',
          completionPercent: 90,
          chapterGate: true,
          quizAttempts: 3,
          retakeWaitHours: 24,
          latePolicy: 'penalty',
          latePenalty: 10,
          atRiskDays: 10,
          learnerPreferences: { playbackSpeed: true, captionsByDefault: false, downloadNotes: true, showRank: true, studyReminders: true },
        }),
        certificatesJson: JSON.stringify({
          enabled: true,
          autoIssue: false,
          minScore: 60,
          defaultTemplateId: classic.id,
          fields: { hours: true, score: true, level: true, signatures: true },
          publicVerification: true,
          credentialPrefix: settingsCredentialPrefix,
          validityMonths: null,
        }),
        notificationsJson: JSON.stringify({
          senderName: academyName,
          replyTo: 'hello@zuviloai.com',
          learner: {
            enrolmentConfirmation: true,
            liveReminderMinutes: [1440, 60, 15],
            assignmentReminderDays: 2,
            weeklyDigest: true,
            inactivityNudge: true,
            certificateIssued: true,
          },
          staff: { newSubmission: true, reviewOverdue: true, dailyEnrolments: false, courseReview: true },
          smsEnabled: true,
        }),
        appearanceJson: JSON.stringify({
          brandName: academyName,
          accent: 'indigo',
          learnerTheme: 'system',
          density: 'comfortable',
          coverArt: true,
          welcomeMessage: 'Pick up where you left off — your next lesson is waiting.',
        }),
        updatedAtJson: JSON.stringify({ general: nowIso, courses: nowIso, learning: nowIso, certificates: nowIso, notifications: nowIso, appearance: nowIso }),
        updatedByJson: JSON.stringify({
          general: 'Kavita Menon',
          courses: 'Kavita Menon',
          learning: 'Kavita Menon',
          certificates: 'Kavita Menon',
          notifications: 'Kavita Menon',
          appearance: 'Kavita Menon',
        }),
      },
    });

    log('Notifications for Ananya...');
    await db.appNotification.create({
      data: {
        ...T,
        recipientId: ananya.userId,
        category: 'live',
        title: 'Live class in 2 days',
        summary: 'Fractions in everyday problems starts soon.',
        bodyJson: JSON.stringify(['Join Dr. Meenakshi Iyer for a live problem-solving session on fractions and decimals.']),
        important: true,
      },
    });
    await db.appNotification.create({
      data: {
        ...T,
        recipientId: ananya.userId,
        category: 'course',
        title: 'Continue Maths Foundations for Classes 6–8',
        summary: 'You’re 38% through — pick up where you left off.',
        bodyJson: JSON.stringify(['Lesson 2.1, Fractions on the number line, is next.']),
      },
    });

    // One paid course, to buy (lib/coursePurchases.ts). Made after every seeded enrolment, so nobody holds it for free,
    // and dated two months back so the catalogue lists it last — not a year, or the inactivity job archives it at boot.
    log('A paid course...');
    const paidCourse = await makeCourse({
      slug: 'class-10-science-sprint',
      title: 'Class 10 Science: Board Exam Sprint',
      subtitle: 'Physics, chemistry and biology revision for the board exam, chapter by chapter.',
      description:
        'A four-week revision course for Class 10 CBSE and RBSE students: the chapters most often examined, worked board questions, and a practice test at the end of each part.',
      levelId: intermediate.id,
      categoryId: catFoundations.id,
      coverMotif: 'orbits',
      instructorIds: [vinod.id],
      price: 1499,
      pricing: 'paid',
      chapters: [
        {
          title: 'Light: reflection and refraction',
          summary: 'Mirrors, lenses and the board questions on them.',
          objective: 'Solve mirror and lens numericals with the sign convention.',
          lessons: [
            { title: 'Reflection and the mirror formula', type: 'reading', durationMin: 15, content: { article: { body: 'The mirror formula relates object distance, image distance and focal length: 1/v + 1/u = 1/f.' } } },
            { title: 'Refraction and lenses', type: 'reading', durationMin: 15, content: { article: { body: 'Snell’s law: the ratio of the sines of the angles of incidence and refraction is constant for two media.' } } },
          ],
        },
      ],
      outcomes: ['Solve mirror and lens numericals', 'Answer board questions on refraction'],
      tags: ['Class 10', 'Science', 'Board exam'],
    });
    await db.course.update({ where: { id: paidCourse.id }, data: { updatedAt: new Date(Date.now() - 60 * 86_400_000) } });

    return {
      admin: admin.email,
      instructors: [meenakshi.email, vinod.email].filter((e): e is string => Boolean(e)),
      students: studentDefs.map((s) => s.email),
    };
  } finally {
    await Promise.all([db.$disconnect(), platform.$disconnect()]);
  }
}
