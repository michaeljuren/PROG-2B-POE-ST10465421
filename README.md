# RaceDay

**Portfolio of Evidence — PROG6212 (Programming 2B)**
Michael-John Uren · ST10465421

RaceDay is a full-stack event management platform for the South African road
running, walking and cycling community. Organizers create and manage events,
categories and results; participants browse and enter events, track their
personal performance history, and prepare for race day using live weather
and route information. The finished platform will be a containerized,
cloud-aware, API-driven **ASP.NET Core MVC** application.

## Progress

### Part 1 — Database design (complete)

A relational database design for the platform, produced before any
application or API code:

| Deliverable | File |
|---|---|
| Entity relationship diagram + schema notes | [`database/RaceDay-ERD.png`](database/RaceDay-ERD.png) |
| SQL Server schema + seed data script | [`database/RaceDay-Schema.sql`](database/RaceDay-Schema.sql) |
| RESTful API endpoint specification | [`documents/API-specification.docx`](documents/API-specification.docx) |


The schema is a normalized (3NF), 10-table design (`Roles`, `Clubs`,
`Users`, `UserRoles`, `Venues`, `Routes`, `Events`, `Categories`,
`Entries`, `Results`) covering organizers, events, categories, entries and
results. Live weather is fetched from an external API rather than stored.

To create and seed the database: open `database/RaceDay-Schema.sql` in SQL
Server Management Studio while connected to a SQL Server instance, then
press F5 to run the whole script. It (re)creates a `RaceDayDB` database with
all tables, constraints and representative sample data.

## Repository structure

```
Database/           SQL Server schema + seed data script & Entity relationship diagram
Docs/               RESTful API endpoint specification
                    
```

## AI Usage Disclosure

- I used Claude to assist with the creation of the database schema. The AI provided suggestions for table structures, relationships, which I then reviewed and modified to fit the specific requirements of the RaceDay platform. It was also used to generate the database seed data, and formatting the README file.

## Tech stack

- ASP.NET Core MVC (application, upcoming)
- SQL Server
