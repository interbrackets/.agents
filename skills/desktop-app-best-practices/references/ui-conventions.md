# UI Conventions

## Keyboard

- Every interaction works from the keyboard, with a visible focus indicator.
- Initial focus goes to the control the user will most likely use first.
- Tab order follows reading order, left to right and top to bottom.
- Give shortcuts to common commands, but never make a shortcut the only way to do something.
- Do not reassign well-known shortcuts such as Ctrl+C, Ctrl+S, or Ctrl+Z.
- Keep shortcuts scoped to the app. Do not claim system-wide shortcuts without a strong reason and a setting to turn them off.
- Enter and Esc map to the default and cancel actions in dialogs.

## Accessibility

- Prefer platform or standard controls, and expose accurate names, roles, states, and values.
- Label every control or group of controls.
- Test critical workflows with Narrator and Accessibility Insights for Windows.
- Treat critical accessibility regressions as release blockers.
- Provide captions or transcripts for audio and video.

## Controls

- Select the safest value by default, then the most likely one.
- Prefer constrained controls such as lists and sliders over free text.
- Reconsider disabled controls: users must guess why they are off. Remove a control the user can never enable, or leave it enabled and explain the problem when used.
- Use specific button labels ("Save changes"), not generic ones.
- Use **Cancel** only if it returns to the previous state with no side effects. Otherwise use **Close** or **Stop**.
- Commit buttons go in the order: OK or [Do it], [Don't do it], Cancel, Apply.
- Use an ellipsis on a command only when it needs more input, not whenever it opens a window.

## Progress

- Use a determinate bar when the work is bounded, even if the time is uncertain.
- Never restart a progress bar. Steps should share one run to completion.
- Show a time estimate only if it is accurate.

## Dialogs

- Use modal dialogs only for what the user must answer before continuing. Otherwise prefer something non-blocking.
- Use confirmations only when the action has significant consequences, cannot be easily undone, or is likely a mistake.
- Do not rely on "Are you sure?" for safety. Users are conditioned to click Yes, so prefer undo or a stronger guardrail.
- Phrase confirmations as yes or no questions, with Yes and No answers.
- Do not select "Don't show this again" by default.

## Error messages

- Show an error only when the user can act on it or needs to know. Otherwise log it.
- Propose a solution that is likely to work.
- Be specific: name the object, location, and value involved.
- Do not blame the user. Avoid "you" and "your" in the phrasing.
- Use **Close**, not OK, on error dialogs. Errors are not OK.
- Avoid harsh words: prefer "problem" to "error" or "failure", "unable to" to "failed to", "not valid" to "illegal" or "invalid", and "stop" to "abort", "kill", or "terminate".
- Do not add a sound to error messages.

Never show a raw exception, stack trace, or error code on its own.

## Notifications

- Use notifications for events unrelated to the current activity that the user can freely ignore.
- For anything critical, use a dialog or in-app UI instead.
- Clicking a notification opens the app in that notification's context.
- Keep them rare and useful. Too many and users turn them off.
- Never use notifications for ads or feature promotion.
- Clear old notifications from Notification Center.

## Wording

- Use plain terms focused on the user's goal, not the technology.
- Use title-style capitalization for titles, and sentence-style for everything else.
- Do not end control labels with a period.
- Avoid truncated text when there is room. Truncation in a window with free space means the layout is wrong.
