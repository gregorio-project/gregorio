--GregorioTeX Signs Lua support file.
--
--Copyright (C) 2015 The Gregorio Project (see CONTRIBUTORS.md)
--
--This file is part of Gregorio.
--
--Gregorio is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--Gregorio is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.

-- this file contains lua functions to support signs used by GregorioTeX.

local err = gregoriotex.module.err
local warn = gregoriotex.module.warn
local info = gregoriotex.module.info
local log = gregoriotex.module.log

-- Note offset cases:
-- here are the common values for both hepisemus (and consequently also for
-- additional lines) and vepisemus
-- this indicates the note
local offset_cases = {
  -- punctum as last note (works with pes)
  {
    case = 'FinalPunctum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum}{1}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@punctum}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- deminutus as last note
  {
    case = 'FinalDeminutus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@smallpunctum}{1}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@smallpunctum}{\gre@char@he@initio{#4}}{2}{#3}]],
  },
  -- second-to-last note, disconnected from prior note, with a second ambitus
  -- of at least two, when last note is a standard punctum (like the second
  -- note of hig)
  {
    case = 'PenultBeforePunctumWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@flexusalt}{\gre@char@punctum}{2}{0}{#2}{#3}{#4}]],
    -- a kind of flexus, it has the good width
    h = [[\gre@hepisorlineaux{\gre@char@flexusalt}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- second-to-last note, when last note is a deminutus
  {
    case = 'PenultBeforeDeminutus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@flexusdeminutus}{1}{0}{#2}{#3}{#4}]],
    -- in order to go to the good place, we first make a kern of - the glyph
    -- before deminutus, which has the same width as a standard flexus deminutus
    h = [[\gre@hepisorlineaux{\gre@char@flexusdeminutus}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- third-to-last note, when the last note is a punctum (for porrectus flexus)
  {
    case = 'AntepenultBeforePunctum',
    v = [[\gre@vepisemusorrareaux{\gre@char@torculus}{\gre@char@punctum}{2}{0}{#2}{#3}{#4}]],
    -- is a torculus, it has the good width
    h = [[\gre@hepisorlineaux{\gre@char@torculus}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- third-to-last note, when the last notes is a deminutus (for porrectus
  -- flexus)
  {
    case = 'AntepenultBeforeDeminutus',
    v = [[\gre@vepisemusorrareaux{\gre@char@torculusdeminutus}{\gre@char@punctum}{2}{0}{#2}{#3}{#4}]],
    -- torculus deminutus has the good width
    h = [[\gre@hepisorlineaux{\gre@char@torculusdeminutus}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- standard punctum as first note, disconnected from next note
  {
    case = 'InitialPunctum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@punctum{#4}}{0}{#3}]],
  },
  -- initio debilis (always the first note)
  {
    case = 'InitioDebilis',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@smallpunctum}{0}{0}{#2}{#3}{#4}]],
    -- we assume that the initio-debilis has the same width as a punctum
    -- deminutus
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@flexus{#4}}{0}{#3}]],
  },
  -- first note of a non-auctus porrectus with a second ambitus of at least two
  {
    case = 'PorrNonAuctusInitialWide',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum}{0}{0}{#2}{#3}{#4}]],
    -- we do (for now) the same as case 6
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@porrectus{#2}{#4}}{0}{#3}]],
  },
  -- first note of a non-auctus porrectus with a second ambitus of one
  {
    case = 'PorrNonAuctusInitialOne',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@porrectus@amone{#2}{#4}}{0}{#3}]],
  },
  -- first note of an auctus porrectus, regardless of second ambitus
  {
    case = 'PorrAuctusInitialAny',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@porrectusfl{#2}{#4}}{0}{#3}]],
  },
  -- punctum inclinatum as last note
  {
    case = 'FinalInclinatum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctuminclinatum}{0}{30\the\gre@factor }{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@punctuminclinatum}{\gre@char@he@inclinatum{#4}}{2}{#3}]],
  },
  -- punctum inclinatum deminutus as last note
  {
    case = 'FinalInclinatumDeminutus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctuminclinatumdem}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@punctuminclinatumdem}{\gre@char@he@inclinatumdem{#4}}{2}{#3}]],
  },
  -- stropha as last note
  {
    case = 'FinalStropha',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@stropha}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@stropha}{\gre@char@he@stropha{#4}}{2}{#3}]],
  },
  -- quilisma as last note
  {
    case = 'FinalQuilisma',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@quilisma}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@quilisma}{\gre@char@he@quilisma{#4}}{2}{#3}]],
  },
  -- oriscus as last note
  {
    case = 'FinalOriscus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@oriscus}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@oriscus}{\gre@char@he@oriscus{#4}}{2}{#3}]],
  },
  -- second-to-last note, with a second ambitus of one, when last note is a
  -- standard punctum (like the second note of ghg)
  {
    case = 'PenultBeforePunctumOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@flexusaltone}{\gre@char@punctum}{2}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@flexusaltone}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- "upper smaller punctum" as last note (concerning simple podatus, podatus,
  -- and torculus resupinus)
  {
    case = 'FinalUpperPunctum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@peshigh}{1}{-30\the\gre@factor}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@peshigh}{\gre@char@he@smallpunctum{#4}}{2}{#3}]],
  },
  -- oriscus as first note, disconnected from next note
  {
    case = 'InitialOriscus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@oriscusauctus}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@oriscus{#4}}{0}{#3}]],
  },
  -- quilisma as first note, disconnected from next note
  {
    case = 'InitialQuilisma',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@quilisma}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@quilisma{#4}}{0}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a punctum,
  -- with a first and second ambitus of at least two
  {
    case = 'TorcResNonAuctusSecondWideWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@punctum@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@punctum@two}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a punctum,
  -- with a first ambitus of one and a second ambitus of at least two
  {
    case = 'TorcResNonAuctusSecondOneWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@punctum@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@punctum@one}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus initio debilis with any
  -- first ambitus and a second ambitus of at least two
  {
    case = 'TorcResDebilisNonAuctusSecondAnyWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@debilis}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@debilis}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- linea punctum (cavum) as last note
  {
    case = 'FinalLineaPunctum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@lineapunctum}{1}{0}{#2}{#3}{#4}]],
    -- the episemus is not quite long enough so I assumed a different width
    -- for now...
    h = [[\gre@hepisorlineaux{\gre@char@pesinitauctusone}{\gre@char@he@punctum{#4}}{2}{#3}]],
  },
  -- standard bar
  {
    case = 'BarStandard',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@divisiominima}{1}{0}{#2}{#3}{#4}]],
  },
  -- virgula
  {
    case = 'BarVirgula',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@virgula}{1}{0}{#2}{#3}{#4}]],
  },
  -- divisio finalis
  {
    case = 'BarDivisioFinalis',
    v = [[\gre@vepisemusorrareaux{0}{\gre@fontchar@divisiofinalis}{1}{0}{#2}{#3}{#4}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a quilisma,
  -- with a first and second ambitus of at least two
  {
    case = 'TorcResQuilismaNonAuctusSecondWideWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@quilisma@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@quilisma@two}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with an oriscus,
  -- with a first and second ambitus of at least two
  {
    case = 'TorcResOriscusNonAuctusSecondWideWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@oriscus@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@oriscus@two}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a quilisma,
  -- with a first ambitus of one and and second ambitus of at least two
  {
    case = 'TorcResQuilismaNonAuctusSecondOneWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@quilisma@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@quilisma@one}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with an oriscus,
  -- with a first ambitus of one and and second ambitus of at least two
  {
    case = 'TorcResOriscusNonAuctusSecondOneWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@oriscus@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@oriscus@one}{\gre@char@he@porrectus{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a punctum,
  -- with a first ambitus of at least two and a second ambitus of one
  {
    case = 'TorcResNonAuctusSecondWideOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@punctum@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@punctum@two}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus initio debilis with any
  -- first ambitus and a second ambitus of one
  {
    case = 'TorcResDebilisNonAuctusSecondAnyOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@debilis}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@debilis}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a quilisma,
  -- with a first ambitus of at least two and a second ambitus of one
  {
    case = 'TorcResQuilismaNonAuctusSecondWideOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@quilisma@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@quilisma@two}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with an oriscus,
  -- with a first ambitus of at least two and a second ambitus of one
  {
    case = 'TorcResOriscusNonAuctusSecondWideOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@oriscus@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@oriscus@two}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a punctum,
  -- with a first and second ambitus of one
  {
    case = 'TorcResNonAuctusSecondOneOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@punctum@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@punctum@one}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with a quilisma,
  -- with a first and second ambitus of one
  {
    case = 'TorcResQuilismaNonAuctusSecondOneOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@quilisma@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@quilisma@one}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of a non-auctus torculus resupinus starting with an oriscus,
  -- with a first and second ambitus of one
  {
    case = 'TorcResOriscusNonAuctusSecondOneOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@oriscus@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@oriscus@one}{\gre@char@he@porrectus@amone{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus starting with a punctum, with
  -- a first ambitus of at least two and any second ambitus
  {
    case = 'TorcResAuctusSecondWideAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@punctum@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@punctum@two}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus initio debilis with any first
  -- and second ambitus
  {
    case = 'TorcResDebilisAuctusSecondAnyAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@debilis}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@debilis}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus starting with a quilisma, with
  -- a first ambitus of at least two and any second ambitus
  {
    case = 'TorcResQuilismaAuctusSecondWideAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@quilisma@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@quilisma@two}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus starting with an oriscus, with
  -- a first ambitus of at least two and any second ambitus
  {
    case = 'TorcResOriscusAuctusSecondWideAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@oriscus@two}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@oriscus@two}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus starting with a punctum, with
  -- a first ambitus of one and any second ambitus
  {
    case = 'TorcResAuctusSecondOneAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@punctum@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@punctum@one}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus starting with a quilisma, with
  -- a first ambitus of one and any second ambitus
  {
    case = 'TorcResQuilismaAuctusSecondOneAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@quilisma@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@quilisma@one}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second note of an auctus torculus resupinus starting with an oriscus, with
  -- a first ambitus of one and any second ambitus
  {
    case = 'TorcResOriscusAuctusSecondOneAny',
    v = [[\gre@vepisemusorrareaux{\gre@char@fuse@oriscus@one}{\gre@char@punctum}{3}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@leading@oriscus@one}{\gre@char@he@porrectusfl{#2}{#4}}{3}{#3}]],
  },
  -- second-to-last note connected to prior note, with a second ambitus of at
  -- least two, when last note is a standard punctum (like the second note of
  -- gig)
  {
    case = 'ConnectedPenultBeforePunctumWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@flexusalt@line@bl}{\gre@char@punctum@line@blbr}{2}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@flexusalt@line@bl}{\gre@char@he@punctum@line@blbr{#4}}{2}{#3}]],
  },
  -- second-to-last note connected to prior note, with a second ambitus of one,
  -- when last note is a standard punctum (like the second note of gih)
  {
    case = 'ConnectedPenultBeforePunctumOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@flexusaltone@line@bl}{\gre@char@punctum@line@bl}{2}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@flexusaltone@line@bl}{\gre@char@he@punctum@line@bl{#4}}{2}{#3}]],
  },
  -- standard punctum as first note, connected to next higher note
  {
    case = 'InitialConnectedPunctum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum@line@tr}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@punctum@line@tr{#4}}{0}{#3}]],
  },
  -- "virga" as first note, connected to next lower note
  {
    case = 'InitialConnectedVirga',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@virga@line@br}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@virga@line@br{#4}}{0}{#3}]],
  },
  -- quilisma as first note, connected to next higher note
  {
    case = 'InitialConnectedQuilisma',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@quilisma@line@tr}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@quilisma@line@tr{#4}}{0}{#3}]],
  },
  -- oriscus as first note, connected to next higher note
  {
    case = 'InitialConnectedOriscus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@oriscus@line@tr}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@oriscus@line@tr{#4}}{0}{#3}]],
  },
  -- punctum as last note, connected to prior higher note
  {
    case = 'FinalConnectedPunctum',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctum}{1}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@punctum@line@tl}{\gre@char@he@punctum@line@tl{#4}}{2}{#3}]],
  },
  -- auctus as last note, connected to prior lower note
  {
    case = 'FinalConnectedAuctus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@punctumauctus@line@bl}{1}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@punctumauctus@line@bl}{\gre@char@he@punctumauctus@line@bl{#4}}{2}{#3}]],
  },
  -- virga aucta as last note
  {
    case = 'FinalVirgaAuctus',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@virgaaucta}{1}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@virgaaucta}{\gre@char@he@punctumauctus@line@bl{#4}}{2}{#3}]],
  },
  -- "virga" as last note, connected to prior lower note
  {
    case = 'FinalConnectedVirga',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@virga@line@br}{1}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@virga@line@br}{\gre@char@he@virga@line@br{#4}}{2}{#3}]],
  },
  -- "virga" as first note, disconnected from next note
  {
    case = 'InitialVirga',
    v = [[\gre@vepisemusorrareaux{0}{\gre@char@virga}{0}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{0}{\gre@char@he@virga{#4}}{0}{#3}]],
  },
  -- "oriscus" as the middle note of a salicus with a second ambitus of at
  -- least two
  {
    case = 'SalicusOriscusWide',
    v = [[\gre@vepisemusorrareaux{\gre@char@pesquassus}{\gre@char@salicus@oriscus}{2}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@pesquassus}{\gre@char@he@salicus@oriscus{#4}}{2}{#3}]],
  },
  -- "oriscus" as the middle note of a salicus with a second ambitus of one
  {
    case = 'SalicusOriscusOne',
    v = [[\gre@vepisemusorrareaux{\gre@char@pesquassusone}{\gre@char@salicus@oriscus}{2}{0}{#2}{#3}{#4}]],
    h = [[\gre@hepisorlineaux{\gre@char@pesquassusone}{\gre@char@he@salicus@oriscus{#4}}{2}{#3}]],
  },
}

local function emit_offset_macros()
  local i, item
  for i, item in ipairs(offset_cases) do
    log([[\def\GreOCase%s{%d}]], item.case, i)
    tex.sprint(string.format([[\def\GreOCase%s{%d}]], item.case, i))
  end
  tex.sprint([[\def\gre@v@case#1#2#3#4{]])
  tex.sprint([[\ifcase#1\gre@bug{Invalid note offset case: \string#1}]])
  for i, item in ipairs(offset_cases) do
    tex.sprint([[\or]])
    if item.v then
      tex.sprint(item.v)
    end
  end
  tex.sprint([[\else\gre@bug{Invalid note 2 offset case: \string#1}]])
  tex.sprint([[\fi}]])
  tex.sprint([[\def\gre@h@case#1#2#3#4{]])
  tex.sprint([[\ifcase#1\gre@bug{Invalid note offset case: \string#1}]])
  for i, item in ipairs(offset_cases) do
    tex.sprint([[\or]])
    if item.h then
      tex.sprint(item.h)
    end
  end
  tex.sprint([[\else\gre@bug{Invalid note offset case: \string#1}]])
  tex.sprint([[\fi}]])
end

gregoriotex.emit_offset_macros   = emit_offset_macros
