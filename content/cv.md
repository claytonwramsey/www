+++
template = "cv.html"
title = "Clayton W. Ramsey"
description = "Clayton Ramsey's curriculum vitae"
+++

{#- Components are in templates/cv_components.html -#}

<address class="cv-contact">
<a href="mailto:claytonwramsey@gmail.com">claytonwramsey@gmail.com</a>
<a href="https://claytonwramsey.com">claytonwramsey.com</a>
<a href="https://www.linkedin.com/in/claytonwramsey">linkedin.com/in/claytonwramsey</a>
</address>

## Education

{% <list> %}
{% <entry title="Rice University" location="Houston, TX" dates="Aug 2023 - Present"> %}
Ph.D., Computer Science (in progress); advised by Dr. Lydia E. Kavraki
{% </entry> %}
{% <entry title="Rice University" location="Houston, TX" dates="Aug 2019 - May 2023"> %}
B.S., Electrical Engineering; B.A., Computer Science
{% </entry> %}
{% </list> %}

## Professional experience

{% <employers> %}
{% <employer name="Rice University" location="Houston, TX" note="Advised by Dr. Lydia E. Kavraki"> %}
{{ <role title="Doctoral Student" dates="Aug 2023 - Present" /> }}
{{ <role title="Undergraduate Researcher" dates="May 2021 - Aug 2022" /> }}
{% </employer> %}
{% <employer name="NASA Johnson Space Center" location="Houston, TX" note="with the Dexterous Robotics Team"> %}
{{ <role title="NSTGRO Research Fellow" dates="May 2026 - Aug 2026, May 2025 - Aug 2025" /> }}
{% </employer> %}
{% <employer name="Stellar Solutions" location="Palo Alto, CA"> %}
{{ <role title="Embedded Systems Intern" dates="May 2020 - Aug 2020" /> }}
{{ <role title="Mechanical Design Intern" dates="Jun 2019 - Aug 2019" /> }}
{% </employer> %}
{% </employers> %}

## Publications

### Peer-reviewed articles and journal papers

{% <list> %}
{% <item> %}
T. Duong, **C. W. Ramsey**, Z. Kingston, W. Thomason, L. E. Kavraki.
"<cite class="cv-title">[Ultrafast Sampling-based Kinodynamic Planning via Differential Flatness.](https://arxiv.org/pdf/2603.16059)</cite>"
<cite>IEEE Transactions on Robotics (T-RO)</cite>, 2026. To appear.
{% </item> %}
{% <item> %}
W. Guo, T. Tyrovouzis, E. Flores, **C. W. Ramsey**, Z. K. Kingston, I. A. Şucan, M. Moll, L. E. Kavraki.
"<cite class="cv-title">[The Open Motion Planning Library 2.0.](https://arxiv.org/pdf/2605.29301)</cite>"
<cite>IEEE Robotics and Automation Magazine (RAM)</cite>, 2026. To appear.
{% </item> %}
{% </list> %}

### Peer-reviewed conference papers

{% <list> %}
{% <item> %}
**C. W. Ramsey**, Z. Kingston\*, W. Thomason\*, L. E. Kavraki.
"<cite class="cv-title">[Collision-Affording Point Trees: SIMD-Amenable Nearest Neighbors for Fast Collision Checking.](https://www.roboticsproceedings.org/rss20/p038.html)</cite>"
<cite>Robotics: Science and Systems (RSS)</cite>, 2024. \*Equal contribution.
{% </item> %}
{% </list> %}

### Workshop papers

{% <list> %}
{% <item> %}
**C. W. Ramsey**, L. E. Kavraki. "<cite class="cv-title">Coroutine Scheduling in Task and Motion Planning.</cite>"
[<cite>IEEE ICRA 2026 Workshop – Robotics Acceleration with Computing Hardware and Systems</cite>](https://sites.google.com/view/roboarch-icra26), 2026.
{% </item> %}
{% <item> %}
**C. W. Ramsey**, Z. Kingston\*, W. Thomason\*, L. E. Kavraki.
"<cite class="cv-title">Dynamic Motion Planning from Perception via Accelerated Point Cloud Collision Checking.</cite>"
[<cite>IEEE ICRA 2024 Workshop – Agile Robotics: From Perception to Dynamic Action</cite>](https://agile-robotics-workshop.github.io/icra2024/), 2024.
\*Equal contribution.
{% </item> %}
{% </list> %}

## Awards and honors

{% <list> %}
{% <dated date="2024"> %}
[<b>NASA Space Technology Graduate Research Opportunities Fellowship</b>](https://www.nasa.gov/directorates/stmd/space-tech-research-grants/nstgro/), NASA
{% </dated> %}
{% <dated date="2024"> %}
[<b>National Defense Science and Engineering Graduate Fellowship</b>](https://ndseg.sysplus.com/NDSEG/about), Department of Defense
{% </dated> %}
{% <dated date="2023"> %}[<b>Eta Kappa Nu Member</b>](https://hkn.ieee.org/), IEEE{% </dated> %}
{% <dated date="Fall 2022 and Spring 2023"> %}
[<b>President's Honor Roll</b>](https://registrar.rice.edu/students/academic-honors), Rice University
{% </dated> %}
{% </list> %}

## Teaching

### Instructor

{% <list> %}
{% <dated date="Spring 2023" note="via the Student Taught Course program at Rice University"> %}<b>Artificial Intelligence for Chess</b>, Rice University{% </dated> %}
{% </list> %}

### Teaching assistant

{% <list> %}
{% <dated date="Fall 2023 and Fall 2024"> %}<b>Algorithmic Robotics</b>, Rice University{% </dated> %}
{% <dated date="Fall 2022"> %}<b>Functional Programming</b>, Rice University{% </dated> %}
{% <dated date="Fall 2020 - Spring 2021"> %}<b>Fundamentals of Computer Engineering</b>, Rice University{% </dated> %}
{% </list> %}

## Invited talks

{% <list> %}
{% <dated date="Aug 5 2026"> %}<cite class="cv-talk">Now you're planning with coroutines</cite>, NASA Johnson Space Center{% </dated> %}
{% <dated date="Jun 2 2026"> %}<cite class="cv-talk">The Open Motion Planning Library (OMPL 2.0)</cite>, IEEE ICRA{% </dated> %}
{% <dated date="Aug 7 2025"> %}<cite class="cv-talk">Running it back with robots</cite>, NASA Johnson Space Center{% </dated> %}
{% <dated date="May 23 2025"> %}
<cite class="cv-talk">SIMD-Accelerated Sampling-Based Motion Planning</cite>,
[RoboARCH Workshop](https://sites.google.com/view/roboarch-icra25/schedule?authuser=0), IEEE ICRA
{% </dated> %}
{% <dated date="May 19 2025"> %}
<cite class="cv-talk">Fast, flexible robot planning in Rust</cite>, [Rust for Robotics Workshop](https://sites.google.com/view/r4rworkshop), IEEE ICRA
{% </dated> %}
{% <group title="<cite class='cv-talk'>Collision-Affording Point Trees: SIMD-Amenable Nearest Neighbors for Fast Collision Checking</cite>"> %}
{% <dated date="Dec 5 2024"> %}NASA Johnson Space Center{% </dated> %}
{% <dated date="Nov 20 2024"> %}University of Houston Downtown{% </dated> %}
{% <dated date="Oct 7 2024"> %}Rice University{% </dated> %}
{% </group> %}
{% </list> %}

## Service

### Reviewer

{% <list> %}
{% <dated date="2026"> %}IEEE Transactions on Automation Science and Engineering (T-ASE){% </dated> %}
{% <dated date="2026"> %}IEEE Transactions on Robotics (T-RO){% </dated> %}
{% <dated date="2026"> %}IEEE International Conference on Intelligent Robots and Systems (IROS){% </dated> %}
{% <dated date="2024, 2025, 2026, 2027"> %}IEEE International Conference on Robotics and Automation (ICRA){% </dated> %}
{% <dated date="2024, 2025, 2026"> %}IEEE Robotics and Automation Letters (RA-L){% </dated> %}
{% <dated date="2025"> %}Rust for Robotics Workshop, IEEE ICRA{% </dated> %}
{% <dated date="2024"> %}International Journal of Robotics Research (IJRR){% </dated> %}
{% </list> %}

### Volunteer

{% <list> %}
{% <dated date="2026"> %}Professional communication coach, Rice University{% </dated> %}
{% <dated date="2025"> %}
[Workshop on Language and Semantics of Task and Motion Planning](https://dyalab.mines.edu/2025/icra-workshop/), IEEE ICRA
{% </dated> %}
{% </list> %}

## Open source software

### Maintainer

{% <list> %}
{% <dated date="2025 - Present"> %}[Vector-Accelerated Motion Planner (VAMP)](https://github.com/KavrakiLab/vamp){% </dated> %}
{% <dated date="2023 - Present"> %}[CAPT](https://github.com/KavrakiLab/capt){% </dated> %}
{% <dated date="2023 - Present"> %}[dumpster](https://github.com/claytonwramsey/dumpster){% </dated> %}
{% <dated date="2026 - Present"> %}[mvtable](https://github.com/claytonwramsey/mvtable){% </dated> %}
{% <dated date="2026 - Present"> %}[cricket](https://github.com/CoMMALab/cricket){% </dated> %}
{% </list> %}

### Contributor

{% <list> %}
{% <dated date="2025 - Present"> %}[Open Motion Planning Library (OMPL)](https://github.com/ompl/ompl){% </dated> %}
{% <dated date="2026"> %}[rerun](https://github.com/rerun-io/rerun){% </dated> %}
{% <dated date="2025"> %}[kiddo](https://github.com/sdd/kiddo){% </dated> %}
{% </list> %}

## Other activities

{% <list> %}
{% <dated date="2026"> %}<b>First Place</b>, amateur Paso Doble, USA Dance National Championships{% </dated> %}
{% <dated date="2018, 2022, 2024"> %}
[<b>Gold Medalist</b>](https://www.usfigureskating.org/skate/test-structure), United States Figure Skating
{% </dated> %}
{% <item> %}Latin – intermediate reading comprehension{% </item> %}
{% </list> %}

<footer>
<p>Last updated <time datetime="2026-10">October 2026</time>.</p>
</footer>
