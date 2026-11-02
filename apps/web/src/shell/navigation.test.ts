import { describe, expect, it } from 'vitest';
import { bottomDestinations, flatItems, locate, navigation, visibleNavigation, workspaceLabel } from './navigation';

const destinations = (role: Parameters<typeof flatItems>[0]) => flatItems(role).map((item) => item.to);

describe('the platform owner’s navigation (docs/16 §2.2)', () => {
  it('runs the workspace and the platform from one sidebar', () => {
    expect(flatItems('superadmin').map((item) => item.label)).toEqual([
      'Dashboard',
      'Courses',
      'Students',
      'Instructors',
      'Reports',
      'Reviews',
      'Platform settings',
      'Admin users',
      'All users',
      'Orders & payments',
      'Affiliate program',
      'Website',
      'Inbox',
      'Notifications',
      'Activity log',
      'System health',
      'Logo & branding',
    ]);
    expect(destinations('superadmin')).toEqual([
      '/superadmin',
      '/admin/courses',
      '/admin/students',
      '/admin/instructors',
      '/admin/reports',
      '/admin/reviews',
      '/admin/settings',
      '/superadmin/admins',
      '/superadmin/users',
      '/superadmin/sales/orders',
      '/superadmin/affiliates/overview',
      '/superadmin/website',
      '/superadmin/inquiries',
      '/superadmin/notifications',
      '/superadmin/audit',
      '/superadmin/system',
      '/superadmin/branding',
    ]);
    expect(workspaceLabel.superadmin).toBe('Platform owner');
    expect(bottomDestinations.superadmin.every((id) => flatItems('superadmin').some((item) => item.id === id))).toBe(true);
  });

  it('names no plan, subscription or academy page', () => {
    for (const to of destinations('superadmin')) expect(to).not.toMatch(/subscriptions|academies|billing/);
  });

  it('matches the page a path belongs to, and claims nothing outside it', () => {
    expect(locate('superadmin', '/superadmin/users')?.item.label).toBe('All users');
    // The workspace root matches only itself, so a child page does not light up the dashboard.
    expect(locate('superadmin', '/superadmin/audit')?.item.label).toBe('Activity log');
    expect(locate('superadmin', '/admin/courses/c1/curriculum')?.item.label).toBe('Courses');
    expect(locate('superadmin', '/admin/quizzes')?.leaf?.label).toBe('Quizzes');
    expect(locate('superadmin', '/superadmin/payment-gateways')?.leaf?.label).toBe('Payment setup');
    expect(locate('superadmin', '/superadmin/affiliates/orders')?.leaf?.label).toBe('Orders');
    // A workspace page outside the owner's sidebar still has a name in the header.
    expect(locate('superadmin', '/admin/calendar')?.item.label).toBe('Calendar');
    expect(locate('superadmin', '/notifications')).toBeUndefined();
  });
});

describe('the staff admin’s navigation', () => {
  it('keeps the admin sidebar to the workspace, without a billing page or appearance settings (docs/16 §2.3)', () => {
    expect(navigation.admin.map((group) => group.id)).toEqual(['dashboard', 'catalog', 'people', 'insight']);
    expect(destinations('admin')).toEqual([
      '/admin',
      '/admin/courses',
      '/admin/quizzes',
      '/admin/assignments',
      '/admin/live',
      '/admin/certificates',
      '/admin/students',
      '/admin/instructors',
      '/admin/reports',
      '/admin/reviews',
      '/admin/calendar',
      '/admin/settings',
      '/admin/help',
    ]);
    const settings = flatItems('admin').find((i) => i.id === 'settings')!;
    expect(settings.children!.map((c) => c.label)).toEqual(['General', 'Courses', 'Learning', 'Certificates', 'Notifications']);
    expect(bottomDestinations.admin).toEqual(['dashboard', 'courses', 'students', 'reports']);
    expect(workspaceLabel.admin).toBe('Admin');
  });

  it('keeps the instructor and learner sidebars, with course sales for instructors', () => {
    expect(destinations('instructor')).toEqual([
      '/teach',
      '/teach/courses',
      '/teach/course-sales',
      '/teach/reports',
      '/teach/reviews',
      '/teach/quizzes',
      '/teach/assignments',
      '/teach/live',
      '/teach/students',
      '/teach/calendar',
      '/teach/help',
    ]);
    expect(destinations('student')).toEqual([
      '/home',
      '/explore',
      '/my-learning',
      '/live',
      '/assignments',
      '/assessments',
      '/certificates',
      '/affiliate',
      '/help',
    ]);
  });

  it('shows no platform destination to any workspace role', () => {
    for (const role of ['student', 'instructor', 'admin'] as const) {
      expect(
        destinations(role).some((to) => to.startsWith('/superadmin')),
        role,
      ).toBe(false);
    }
  });

  it('filters the admin sidebar by what the account may open, and nobody else’s', () => {
    const onlyCourses = visibleNavigation('admin', (to) => to.startsWith('/admin/courses'));
    expect(onlyCourses.flatMap((g) => g.items).map((i) => i.id)).toEqual(['courses']);
    expect(visibleNavigation('student', () => false)).toEqual(navigation.student);
  });
});
