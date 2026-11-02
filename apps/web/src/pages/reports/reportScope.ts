/** The tabs a workspace's reports have, under its base. An instructor reports on their own courses and no one else. */
export function reportTabs(base: string, isTeaching: boolean): { key: 'overview' | 'courses' | 'learners' | 'instructors' | 'enrolments'; to: string }[] {
  const reports = `${base}/reports`;
  return [
    { key: 'overview' as const, to: reports },
    { key: 'courses' as const, to: `${reports}/courses` },
    ...(isTeaching
      ? []
      : [
          { key: 'learners' as const, to: `${reports}/learners` },
          { key: 'instructors' as const, to: `${reports}/instructors` },
          { key: 'enrolments' as const, to: `${reports}/enrolments` },
        ]),
  ];
}

/**
 * Which instructor a report is for. In the teaching workspace it is the signed-in one, whatever the address says; the API
 * enforces that from the token, and this keeps the demo build the same. An admin picks from the filter.
 */
export const reportInstructor = (params: URLSearchParams, workspace: { isTeaching: boolean; instructorId?: string }) =>
  workspace.isTeaching ? workspace.instructorId || undefined : params.get('instructor') || undefined;
