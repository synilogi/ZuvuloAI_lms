import type { Category, Course, Level } from './catalog';

export interface TaxonomyCategoryNode {
  category: Category;
  courses: Course[];
}

export interface TaxonomyLevelNode {
  level: Level;
  categories: TaxonomyCategoryNode[];
  courseCount: number;
}

/** Builds Level → Category → Course from flat collections. Empty branches are dropped. */
export function buildTaxonomy(levels: Level[], categories: Category[], courses: Course[]): TaxonomyLevelNode[] {
  return [...levels]
    .sort((a, b) => a.order - b.order)
    .map((level) => {
      const nodes = [...categories]
        .filter((c) => c.levelIds.includes(level.id))
        .sort((a, b) => a.order - b.order)
        .map((category) => ({
          category,
          courses: courses.filter((course) => course.levelId === level.id && course.categoryId === category.id),
        }))
        .filter((n) => n.courses.length > 0);
      return { level, categories: nodes, courseCount: nodes.reduce((n, c) => n + c.courses.length, 0) };
    })
    .filter((n) => n.courseCount > 0);
}

/** Zero-based position of a level within the ordered progression. */
export function levelPosition(levels: Level[], levelId: string) {
  const ordered = [...levels].sort((a, b) => a.order - b.order);
  return { index: ordered.findIndex((l) => l.id === levelId), total: ordered.length };
}
