import type {
  CertificateRecord,
  CoursePurchase,
  CourseQuote,
  CourseReview,
  LearnerCourseReview,
  LearnerQuizQuestion,
  LiveClass,
  QuizSessionStart,
  QuizSessionView,
} from '@syniastrolms/domain';

import type {
  CertificateDetail,
  CompletionResult,
  CoursePurchaseConfirmation,
  CoursePurchaseStart,
  LearnerAssessment,
  LearnerAssignment,
  LearnerCourse,
  LearningHome,
  LearningService,
  LessonView,
  QuizAttemptsView,
  QuizSubmitResult,
} from '../contracts';
import { get, post, put } from './client';

const lessonPath = (courseId: string, lessonId: string) => `/learning/courses/${courseId}/lessons/${lessonId}`;

export const httpLearning: LearningService = {
  getHome: () => get<LearningHome>('/learning/home'),
  listCourses: () => get<{ courses: LearnerCourse[]; saved: LearningHome['saved'] }>('/learning/courses'),
  getCourse: (courseId) =>
    get<LearnerCourse & { enrolled: boolean; live: LiveClass[]; assignments: LearnerAssignment[]; certificate?: CertificateRecord; saved: boolean }>(
      `/learning/courses/${courseId}`,
    ),
  getLesson: (courseId, lessonId) => get<LessonView>(`/learning/courses/${courseId}/lessons/${lessonId}`),
  completeLesson: (courseId, lessonId) => post<CompletionResult>(`/learning/courses/${courseId}/lessons/${lessonId}/complete`),
  savePosition: (courseId, lessonId, positionSec, fraction) =>
    put<void>(`/learning/courses/${courseId}/lessons/${lessonId}/position`, { positionSec, fraction }),
  saveNote: (courseId, lessonId, text) => put<{ savedAt: string }>(`/learning/courses/${courseId}/lessons/${lessonId}/note`, { text }),
  toggleBookmark: (courseId, lessonId) => post<{ bookmarked: boolean }>(`/learning/courses/${courseId}/lessons/${lessonId}/bookmark`),
  toggleSaved: (courseId) => post<{ saved: boolean }>(`/learning/courses/${courseId}/save`),
  enroll: (courseId) => post<LearnerCourse>(`/learning/courses/${courseId}/enroll`),
  listAssignments: () => get<LearnerAssignment[]>('/learning/assignments'),
  getAssignment: (assignmentId) => get<LearnerAssignment>(`/learning/assignments/${assignmentId}`),
  saveAssignmentDraft: (assignmentId, draft) => put<{ savedAt: string }>(`/learning/assignments/${assignmentId}/draft`, draft),
  submitAssignment: (assignmentId, draft) => post<LearnerAssignment>(`/learning/assignments/${assignmentId}/submit`, draft),
  listAssessments: () => get<LearnerAssessment[]>('/learning/assessments'),
  quizAttempts: (courseId, lessonId) => get<QuizAttemptsView>(`${lessonPath(courseId, lessonId)}/quiz-attempts`),
  startQuizSession: (courseId, lessonId, startKey) => post<QuizSessionStart>(`${lessonPath(courseId, lessonId)}/quiz-session`, startKey ? { startKey } : {}),
  getQuizSession: (courseId, lessonId) =>
    get<{ session: QuizSessionView | null; questions: LearnerQuizQuestion[] }>(`${lessonPath(courseId, lessonId)}/quiz-session`),
  saveQuizAnswers: (courseId, lessonId, sessionId, answers, seq) =>
    put<QuizSessionView>(`${lessonPath(courseId, lessonId)}/quiz-session/${encodeURIComponent(sessionId)}/answers`, { answers, seq }),
  submitQuizSession: (courseId, lessonId, sessionId, final) =>
    post<QuizSubmitResult>(`${lessonPath(courseId, lessonId)}/quiz-session/${encodeURIComponent(sessionId)}/submit`, final ?? {}),
  listCertificates: () => get<{ issued: CertificateDetail[]; pending: CertificateDetail[]; working: CertificateRecord[] }>('/learning/certificates'),
  getCertificate: (id) => get<CertificateDetail>(`/learning/certificates/${id}`),
  claimCertificate: (id) => post<CertificateDetail>(`/learning/certificates/${id}/claim`),
  // Course purchases: the client names only the course; the server prices it and verifies every payment.
  quotePurchase: (courseId, couponCode) => post<CourseQuote>(`/learning/courses/${encodeURIComponent(courseId)}/quote`, couponCode ? { couponCode } : {}),
  startPurchase: (courseId, couponCode) =>
    post<CoursePurchaseStart>(`/learning/courses/${encodeURIComponent(courseId)}/purchase`, couponCode ? { couponCode } : {}),
  confirmPurchase: (purchaseId, completion) =>
    post<CoursePurchaseConfirmation>(`/learning/purchases/${encodeURIComponent(purchaseId)}/confirm`, {
      paymentId: completion.paymentId,
      signature: completion.signature,
    }),
  getPurchase: (purchaseId) => get<CoursePurchase>(`/learning/purchases/${encodeURIComponent(purchaseId)}`),
  listPurchases: async () => (await get<{ rows: CoursePurchase[] }>('/learning/purchases')).rows,
  getCourseReview: (courseId) => get<LearnerCourseReview>(`/learning/courses/${encodeURIComponent(courseId)}/review`),
  saveCourseReview: (courseId, input) => put<CourseReview>(`/learning/courses/${encodeURIComponent(courseId)}/review`, input),
};
