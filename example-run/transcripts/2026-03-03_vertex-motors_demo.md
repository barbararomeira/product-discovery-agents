---
date: 2026-03-03
title: Vertex Motors — demo and technical review
ran_by: Tom Becker
participants:
  - tom.becker@northwind.example (Northwind Robotics)
  - k.novak@vertexmotors.example (Vertex Motors, Head of Manufacturing IT)
  - r.adeyemi@vertexmotors.example (Vertex Motors, Operations)
link: https://example.com/calls/1002
---

**Tom Becker** [00:02:10] I will show the line dashboard first, then downtime.

**R. Adeyemi** [00:06:55] Stop there. That view, the one comparing yesterday to the same day
last week. That is the argument I have been trying to make with a spreadsheet for a year.
That alone would save my team a morning a week.

**Tom Becker** [00:07:30] Good. That is live today.

**K. Novak** [00:12:40] My questions are boring ones. Identity first. We do not create local
accounts for tools any more. Everything goes through our identity provider. If a system does
not do SAML, our security review stops it before it reaches procurement.

**Tom Becker** [00:13:15] SAML is committed for Q3.

**K. Novak** [00:13:22] Then we would be signing something we cannot deploy until Q3. I am
not saying no. I am saying it is a gate, not a wish. Write that down.

**R. Adeyemi** [00:18:05] Practical one from me. Half my supervisors do not sit at a desk.
They have a phone in their pocket and that is it. If they cannot see the line status on that
phone, they will not use this, no matter how good it is.

**Tom Becker** [00:18:40] Mobile is on the roadmap for Q3 as well, read-only to start.

**R. Adeyemi** [00:18:52] Read-only is fine. Seeing is the whole job.

**K. Novak** [00:24:30] Now the one I expect you to say no to. We want the raw numbers in our
own warehouse. Not a CSV someone downloads. An endpoint we can pull from every night.

**Tom Becker** [00:25:02] I have to be straight with you, that is not on our roadmap right now.

**K. Novak** [00:25:15] Understood, and I appreciate you not pretending. It is not a blocker
for the pilot. It becomes one at renewal, when this has to live inside our reporting stack
like everything else.

**R. Adeyemi** [00:31:40] Last thing. Your downtime chart looked beautiful and told me nothing
about why. Every stop reason is a category. Categories do not tell me what to fix on Tuesday.

**Tom Becker** [00:32:20] What would tell you?

**R. Adeyemi** [00:32:31] The pattern. Same station, same shift, three times this week. If the
system spotted that and said it out loud, I would trust it more than any chart.
