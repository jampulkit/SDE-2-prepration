# Company-Specific Behavioral Preparation

## 1. Amazon — Leadership Principles [🔥 Must Know]

**Amazon behavioral interviews are 100% LP-based. Each interviewer is assigned 2-3 LPs to evaluate. Prepare at least one story per LP.**

| LP | What They Look For | Sample Question | Story to Use |
|----|-------------------|----------------|-------------|
| **Customer Obsession** | Start with the customer, work backwards | "Tell me about a time you went above and beyond for a customer" | Story 5 (ambiguous requirements, talked to merchants) |
| **Ownership** | Think long-term, act on behalf of the company | "Tell me about a time you took on something outside your scope" | Story 10 (fixed alerting nobody owned) |
| **Invent and Simplify** | Find simpler solutions, innovate | "Tell me about a time you simplified a process" | Story 5 (SSE over WebSocket) |
| **Are Right, A Lot** | Good judgment, seek diverse perspectives | "Tell me about a time you made a decision with incomplete data" | Story 5 (defined "real-time" from merchant interviews) |
| **Learn and Be Curious** | Always learning, explore new possibilities | "Tell me about something you learned recently" | Story 6 (learned zero-downtime migrations after failure) |
| **Hire and Develop the Best** | Raise the bar, mentor others | "Tell me about a time you mentored someone" | Story 4 (mentored junior on retry patterns) |
| **Insist on the Highest Standards** | Relentlessly high standards | "Tell me about a time you refused to compromise on quality" | Story 7 (rounding standard alignment) |
| **Think Big** | Bold direction, think differently | "Tell me about an innovative idea you proposed" | Story 1 (microservices migration) |
| **Bias for Action** | Speed matters, calculated risk-taking | "Tell me about a time you took a calculated risk" | Story 2 (quick rollback during incident) |
| **Frugality** | Do more with less | "Tell me about a time you achieved results with limited resources" | Story 8 (scope cut for on-time launch) |
| **Earn Trust** | Listen, speak candidly, treat others respectfully | "Tell me about a time you earned someone's trust" | Story 3 (data-driven disagreement with manager) |
| **Dive Deep** | Stay connected to details, audit frequently | "Tell me about a time you found a root cause" | Story 2 (traced connection pool exhaustion) |
| **Have Backbone; Disagree and Commit** | Challenge decisions, then commit | "Tell me about a time you disagreed with your manager" | Story 3 (PostgreSQL vs DynamoDB) |
| **Deliver Results** | Focus on key inputs, deliver with quality | "Tell me about a time you delivered under a tight deadline" | Story 8 (scope cut, launched on time) |
| **Strive to be Earth's Best Employer** | Work environment, safety, empathy | "Tell me about a time you helped a teammate" | Story 4 (mentoring approach) |
| **Success and Scale Bring Broad Responsibility** | Impact beyond your team | "Tell me about a time you considered broader impact" | Story 7 (company-wide rounding standard) |

**Amazon SDE-2 bar:** Stories must show IMPACT beyond your immediate task. "I fixed a bug" is SDE-1. "I identified a systemic issue, proposed a solution, and it prevented future incidents for the whole team" is SDE-2.

### The Bar Raiser Round [🔥 Must Know]

**What is a Bar Raiser?**
- A specially trained interviewer from a DIFFERENT team (not the hiring team)
- Their job: ensure every hire raises the bar — would this person make the team better?
- They have VETO power. Even if 3/4 interviewers say "Hire", the BR can block
- They evaluate culture fit + LP depth, not just technical skills
- They typically conduct the behavioral round (sometimes combined with a technical round)

**How BR differs from Hiring Manager:**

| Aspect | Hiring Manager | Bar Raiser |
|--------|---------------|------------|
| Perspective | "Can this person do the job?" | "Is this person better than 50% of current SDE-2s at Amazon?" |
| Bias | May lower bar due to urgency to fill role | No hiring pressure — purely evaluates quality |
| Depth | May accept surface-level answers | Will probe 3-4 levels deep on every story |
| Focus | Role-specific skills | LP alignment + long-term potential |
| Veto | Can be overruled by committee | Has veto power |

**How the BR probes deeper — the "Tell me more" chain:**

```
Level 1: "Tell me about a time you disagreed with your manager."
  → You give your STAR story (2-3 min)

Level 2: "What specifically did you disagree about? Walk me through the data you presented."
  → They want DETAILS, not summary. Exact metrics, exact arguments.

Level 3: "What did your manager say in response? How did you handle their counter-argument?"
  → They're testing: did you actually have a real disagreement, or are you making it up?

Level 4: "If you could go back, would you do anything differently?"
  → Self-awareness test. "No, it was perfect" = red flag. Show growth.

Level 5: "How did this change how you handle disagreements now?"
  → They want to see learning and growth, not just a one-time event.
```

**If you can't go 3+ levels deep on a story, it's not a strong enough story. Pick a different one.**

### Amazon LP Deep-Dive Questions (5-7 per LP)

#### Customer Obsession
1. "Tell me about a time you went above and beyond for a customer/user."
2. "Tell me about a time you had to choose between what the customer wanted and what was technically right."
3. "How do you gather customer feedback? Give me an example."
4. "Tell me about a time you said no to a customer request. Why?"
5. "Tell me about a time you anticipated a customer need before they asked."

**Strong answer signals:** Started with the customer problem, not the technical solution. Talked to actual users. Measured customer impact (NPS, satisfaction, adoption rate). Made trade-offs in favor of the customer.

**Weak answer / No Hire signals:** Talked only about technology, never mentioned the customer. "The PM told me what to build." No metrics on customer impact.

#### Ownership
1. "Tell me about a time you took on something outside your job description."
2. "Tell me about a time you saw a problem and fixed it without being asked."
3. "Tell me about a time you owned a project end-to-end."
4. "Tell me about a time you had to make a decision that affected other teams."
5. "Tell me about something you're not proud of in your current codebase. What are you doing about it?"

**Strong:** Took initiative without being asked. Thought about long-term consequences. Owned the outcome (good or bad). Acted on behalf of the company, not just your team.

**Weak:** "My manager assigned it to me." Only did what was in the ticket. Blamed others when things went wrong.

#### Dive Deep
1. "Tell me about a time you found a root cause that others missed."
2. "Tell me about a time you used data to make a decision."
3. "Tell me about a time you questioned a metric or report that seemed off."
4. "Walk me through how you debugged a complex production issue."
5. "Tell me about a time you audited a system and found problems."
6. "Tell me about a time the details mattered — what would have happened if you'd missed them?"

**Strong:** Went beyond the surface symptom. Used logs, metrics, traces to find root cause. Questioned assumptions. Found something others missed. "I noticed the p99 was fine but p99.9 was spiking..."

**Weak:** "I looked at the error message and fixed it." No data, no metrics, no depth. Accepted the first explanation without questioning.

#### Have Backbone; Disagree and Commit
1. "Tell me about a time you disagreed with your manager or a senior engineer."
2. "Tell me about a time you pushed back on a decision you thought was wrong."
3. "Tell me about a time you committed to a decision you disagreed with. How did it go?"
4. "Tell me about a time you changed your mind based on someone else's argument."
5. "Tell me about a time you had to deliver bad news to your team or stakeholders."

**Strong:** Disagreed with DATA, not emotion. Presented alternatives. Once decision was made, committed fully (didn't sabotage or say "I told you so"). Showed respect throughout. Changed mind when presented with better data.

**Weak:** "I just went along with it." OR "I kept arguing even after the decision was made." No data to support the disagreement. Badmouthed the other person.

#### Deliver Results
1. "Tell me about a time you delivered a project under a tight deadline."
2. "Tell me about a time you had to cut scope. How did you decide what to cut?"
3. "Tell me about a time you removed a blocker for your team."
4. "Tell me about your most impactful project. What made it impactful?"
5. "Tell me about a time you had competing priorities. How did you choose?"
6. "Tell me about a time a project was at risk of failing. What did you do?"

**Strong:** Quantified the result ($X saved, Y% improvement, Z fewer incidents). Made hard trade-offs (cut scope, not quality). Delivered despite obstacles. Focused on the most important thing, not everything.

**Weak:** "We delivered on time." (No specifics on YOUR contribution.) No metrics. Didn't mention trade-offs or obstacles.

#### Earn Trust
1. "Tell me about a time you earned the trust of a skeptical stakeholder."
2. "Tell me about a time you made a mistake and had to own up to it."
3. "Tell me about a time you gave difficult feedback to a peer."
4. "Tell me about a time you had to rebuild trust after a failure."
5. "Tell me about a time you were transparent about a risk or problem."

**Strong:** Admitted mistakes openly. Gave credit to others. Was transparent about risks. Listened before responding. Built trust through consistent actions, not words.

**Weak:** Took credit for team work. Hid problems. Blamed others. "I've never made a mistake."

#### Bias for Action
1. "Tell me about a time you made a decision without having all the information."
2. "Tell me about a time you took a calculated risk."
3. "Tell me about a time you chose speed over perfection."
4. "Tell me about a time you unblocked yourself without waiting for help."
5. "Tell me about a reversible decision you made quickly vs an irreversible one you deliberated on."

**Strong:** Distinguished between one-way and two-way door decisions. Acted quickly on reversible decisions. Gathered just enough data for irreversible ones. Didn't let analysis paralysis slow the team.

**Weak:** "I waited for my manager to decide." Over-analyzed a simple decision. OR made a reckless decision without any analysis.

#### Invent and Simplify
1. "Tell me about a time you simplified a complex process or system."
2. "Tell me about an innovative solution you proposed."
3. "Tell me about a time you eliminated unnecessary complexity."
4. "Tell me about a time you automated something that was done manually."
5. "Tell me about a time you challenged the status quo."

**Strong:** Reduced complexity (fewer services, simpler architecture, less code). Automated toil. Proposed a novel approach that others hadn't considered. Measured the simplification (X% less code, Y fewer steps, Z minutes saved per deploy).

**Weak:** Added complexity and called it innovation. "We added a new microservice" without justifying why.

### Instant "No Hire" Signals in Behavioral

| Signal | Why It's Fatal |
|--------|---------------|
| Using "we" for everything, never "I" | Can't identify YOUR contribution |
| No metrics in any story | Can't demonstrate impact |
| Blaming others for failures | Lack of ownership |
| "I've never failed / disagreed / had conflict" | Either lying or lacks self-awareness |
| Same story for every question | Insufficient experience depth |
| Can't go deeper when probed | Story might be fabricated or you weren't actually involved |
| Badmouthing current employer/manager | Lack of professionalism |
| No lessons learned from failures | No growth mindset |
| Vague answers ("I improved performance") | No specifics = no credibility |
| Taking 5+ minutes per answer | Can't communicate concisely |

### How to Handle "Tell Me More"

When the BR says "tell me more about X" or "can you go deeper on that":

1. **Don't panic** — this is GOOD. It means they're interested, not that you failed.
2. **Go one level deeper** — add specific details you skipped in the initial answer:
   - Exact numbers: "The latency went from 450ms p99 to 120ms p99"
   - Specific actions: "I wrote a 2-page design doc comparing 3 approaches"
   - Names of technologies: "I used JProfiler to identify the hotspot"
3. **If you don't remember the detail** — say "I don't recall the exact number, but it was in the range of..." Honesty > fabrication.
4. **If they ask "what would you do differently"** — ALWAYS have an answer. "In hindsight, I would have involved the QA team earlier" shows self-awareness.

### LP Pairs (Commonly Evaluated Together)

Interviewers are often assigned LP pairs. Prepare stories that hit both:

| LP Pair | Why Together | Story Should Show |
|---------|-------------|-------------------|
| Ownership + Deliver Results | Own it AND ship it | End-to-end project with measurable outcome |
| Dive Deep + Are Right, A Lot | Data-driven depth | Found root cause using data, made correct decision |
| Have Backbone + Earn Trust | Disagree respectfully | Pushed back with data, maintained relationship |
| Customer Obsession + Invent and Simplify | Solve customer problems simply | Talked to users, built simple solution |
| Bias for Action + Deliver Results | Move fast AND deliver | Quick decision that led to successful outcome |
| Hire and Develop the Best + Earn Trust | Grow others through trust | Mentored someone, they succeeded |

## 2. Google

**Google evaluates 4 attributes:**

| Attribute | What They Look For | How to Show It |
|-----------|-------------------|---------------|
| **General Cognitive Ability** | Problem-solving, learning ability | Show structured thinking, how you broke down ambiguous problems |
| **Leadership** | Emergent leadership (not just title) | Times you stepped up without being asked, influenced without authority |
| **Googleyness** | Comfort with ambiguity, collaborative, pushback with data | Disagreement stories, working with diverse teams, intellectual humility |
| **Role-Related Knowledge** | Technical depth for the role | Technical decision stories with trade-off analysis |

**Google tips:**
- Google values intellectual humility. Admit what you didn't know and how you learned.
- "Googleyness" = would I want to work with this person? Be collaborative, not combative.
- Show structured problem-solving: "I broke the problem into 3 parts..."

## 3. Meta (Facebook)

**Meta evaluates against their core values:**

| Value | What They Look For | Story Mapping |
|-------|-------------------|--------------|
| **Move Fast** | Ship quickly, iterate, don't over-engineer | Story 8 (scope cut for speed) |
| **Be Bold** | Take risks, propose big ideas | Story 1 (migration proposal) |
| **Focus on Impact** | Prioritize high-impact work | Story 5 (talked to users first) |
| **Be Open** | Transparent communication, share information | Story 6 (postmortem, shared learnings) |
| **Build Social Value** | Consider broader impact | Story 7 (company-wide standard) |

**Meta tips:**
- Meta loves "move fast" stories. Show you shipped something quickly and iterated.
- Impact is king. Quantify everything. "$50K saved" beats "improved performance."
- Be prepared for "Why Meta?" with a genuine answer about their products/mission.

## 4. Flipkart / Atlassian

**Flipkart values:**
- Customer focus (Indian market nuances)
- Ownership and accountability
- Speed of execution
- Data-driven decisions

**Atlassian values:**
- Open company, no BS (transparency)
- Build with heart and balance (user empathy)
- Don't #@!% the customer
- Play as a team
- Be the change you seek

**Tips for Indian companies:**
- Stories about scale (handling millions of users) resonate well
- Show awareness of India-specific challenges (payment failures, network issues, regional languages)
- Flipkart: payment domain experience is a strong differentiator for you

## 5. SDE-2 vs SDE-1 Behavioral Differences

| Aspect | SDE-1 | SDE-2 |
|--------|-------|-------|
| Scope | Individual tasks | Projects spanning multiple components |
| Impact | "I fixed a bug" | "I identified a systemic issue and prevented future incidents" |
| Influence | Follow instructions | Propose solutions, influence team decisions |
| Mentoring | Not expected | Expected to grow junior engineers |
| Ambiguity | Given clear requirements | Define requirements from vague asks |
| Conflict | Avoid or escalate | Resolve with data, disagree and commit |
| Technical depth | "I used X technology" | "I chose X over Y because of trade-offs A, B, C" |

## 6. Revision Checklist

- [ ] Amazon: prepare 1 story per LP (16 LPs). Focus on Ownership, Dive Deep, Deliver Results, Have Backbone.
- [ ] Google: show structured thinking, intellectual humility, emergent leadership.
- [ ] Meta: quantify impact, show speed of execution, be genuine about "Why Meta?"
- [ ] SDE-2 bar: impact beyond immediate task, influence without authority, mentor others.
- [ ] Map your stories to each company's values BEFORE the interview.
- [ ] Practice out loud with a timer. 2-3 minutes per story.

> 🔗 **See Also:** [08-behavioral/01-behavioral-prep.md](01-behavioral-prep.md) for STAR method. [08-behavioral/02-story-bank.md](02-story-bank.md) for pre-written stories.
