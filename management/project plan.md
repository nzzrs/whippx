# whippx - project plan

i really doubt that i will have any other contributor other than myself, so the plan is to carry the project alone and  finish it in one month, my vacation.

## gantt diagram

this is the schedule:

```mermaid

%%{init: {"theme": "dark", "gantt": {"axisFormat": "%m-%d"}}}%%

gantt

title whippx - gantt diagram

dateFormat YYYY-MM-DD

section sprint 1

	project plan               :a1, 2024-07-14, 2d
	cronogram                  :a2, 2024-07-14, 2d
	WHP-RQNLDC                 :a3, 2024-07-15, 2d
	WHP-NTDS                   :a4, after a3,   2d
	WHP-RCDC                   :a5, after a3,   2d

section sprint 2

	training                   :b1, 2024-07-21, 3d
	UC-01 essays               :b2, after b1,   2d
	report                     :b3, after b2,   1d

section sprint 3

	UC-01 implementation       :c1, 2024-07-28, 4d
	proofs                     :c2, after c1,   2d
	report                     :c3, after c2,   1d

section sprint 4

	UC-02 implementation       :d1, 2024-08-05, 4d
	proofs                     :d2, after d1,   2d
	report                     :d3, after d2,   1d

```