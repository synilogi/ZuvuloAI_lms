# LMS-004 — Chapter Management

## Goal
Create curriculum chapter management connected visually to a selected course.

## Screens
1. Course Curriculum / Chapter List
2. Add Chapter
3. Edit Chapter
4. Chapter Overview
5. Reorder/Move UI

## Chapter List
Show:
- chapter number
- chapter title
- description/summary
- lesson count
- completion indicator
- duration
- status
- actions

Support:
- expand/collapse
- add chapter
- edit
- duplicate UI
- reorder UI
- collapse all/expand all where useful

## Chapter Form
Fields:
- chapter title
- short description
- learning objective
- estimated duration
- visibility/status

## UX
Make hierarchy obvious: Course → Chapter → Lesson.
Use subtle indentation and clear separators, not excessive nested cards.

## States
Empty curriculum, loading, validation, success, error.

## Responsive
Use an accordion/tree-like mobile layout.
