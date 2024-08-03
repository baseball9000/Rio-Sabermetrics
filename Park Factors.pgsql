-- Park Factors 8/23/22
-- Updated on 4/18/23 for Rio 1.9.5 data
-- Updated on 8/3/24 to fix broken joins, union all main gametypes together
-- thanners on Discord

WITH games_per_gametype AS (
select ts.name_lowercase as gametype,
       case when ga.stadium_id::text ='0' then 'Mario Stadium'
            when ga.stadium_id::text ='1' then 'Bowsers Castle'
            when ga.stadium_id::text ='2' then 'Warios Palace'
            when ga.stadium_id::text ='3' then 'Yoshis Island'
            when ga.stadium_id::text ='4' then 'Peachs Garden'
            when ga.stadium_id::text ='5' then 'DKs Jungle'
            when ga.stadium_id::text ='6' then 'Toy Field'
            else 'unknown stadium name'
        end stadium_name,
        count(distinct ga.game_id) as games_played
    from game ga
    left join game_history gh on ga.game_id = gh.game_id
    left join tag_set ts on gh.tag_set_id = ts.id
    where ts.name_lowercase in ('s9superstarson', 's9superstarsoff', 's9bigballa', 's9superstarsoffhazards')
    group by 1,2
) 

select distinct final.*, gpg.games_played from (

select * from (
select stadium_name,
       to_char(float8 (runs_per_game/runs_per_game_ms)::dec,'FM999999999.00')::dec park_factor_runs,
       to_char(float8 (singles_per_game/singles_ms)::dec,'FM999999999.00')::dec park_factor_singles,
       to_char(float8 (doubles_per_game/doubles_ms)::dec,'FM999999999.00')::dec park_factor_doubles,
       to_char(float8 (triples_per_game/triples_ms)::dec,'FM999999999.00')::dec park_factor_triples,
       to_char(float8 (hr_per_game/homers_ms)::dec,'FM999999999.00')::dec park_factor_homers,
       to_char(float8 (star_hits_per_game/starhits_ms)::dec,'FM999999999.00')::dec park_factor_starhits
 from(

 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game,

       b.runs_per_game runs_per_game_ms,
       b.singles_per_game singles_ms,
       b.doubles_per_game doubles_ms,
       b.triples_per_game triples_ms,
       b.hr_per_game homers_ms,
       b.star_hits_per_game starhits_ms

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarson'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id

)a

--select * from character_game_summary where game_id ='245171094785'

cross join 
(select stadium_name mario_stadium_value, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game
 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarson'

                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
)a
where lower(stadium_name)= 'mario stadium'
group by 1
)b
 group by 1,8,9,10,11,12,13
order by runs_per_game
)c
group by 1,
runs_per_game, runs_per_game_ms,
singles_per_game, singles_ms,
doubles_per_game, doubles_ms,
triples_per_game, triples_ms,
hr_per_game, homers_ms,
star_hits_per_game, starhits_ms
)tbl
cross join
(select 's9superstarson' as gametype, 'park factor' as metric) gt

UNION

select * from (
select stadium_name,
       to_char(float8 (runs_per_game/runs_per_game_ms)::dec,'FM999999999.00')::dec park_factor_runs,
       to_char(float8 (singles_per_game/singles_ms)::dec,'FM999999999.00')::dec park_factor_singles,
       to_char(float8 (doubles_per_game/doubles_ms)::dec,'FM999999999.00')::dec park_factor_doubles,
       to_char(float8 (triples_per_game/triples_ms)::dec,'FM999999999.00')::dec park_factor_triples,
       to_char(float8 (hr_per_game/homers_ms)::dec,'FM999999999.00')::dec park_factor_homers,
       to_char(float8 (star_hits_per_game/starhits_ms)::dec,'FM999999999.00')::dec park_factor_starhits
 from(

 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game,

       b.runs_per_game runs_per_game_ms,
       b.singles_per_game singles_ms,
       b.doubles_per_game doubles_ms,
       b.triples_per_game triples_ms,
       b.hr_per_game homers_ms,
       b.star_hits_per_game starhits_ms

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarsoff'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id

)a

--select * from character_game_summary where game_id ='245171094785'

cross join 
(select stadium_name mario_stadium_value, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game
 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarsoff'

                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
)a
where lower(stadium_name)= 'mario stadium'
group by 1
)b
 group by 1,8,9,10,11,12,13
order by runs_per_game
)c
group by 1,
runs_per_game, runs_per_game_ms,
singles_per_game, singles_ms,
doubles_per_game, doubles_ms,
triples_per_game, triples_ms,
hr_per_game, homers_ms,
star_hits_per_game, starhits_ms
)tbl
cross join
(select 's9superstarsoff' as gametype, 'park factor' as metric) gt

UNION

select * from (
select stadium_name,
       to_char(float8 (runs_per_game/runs_per_game_ms)::dec,'FM999999999.00')::dec park_factor_runs,
       to_char(float8 (singles_per_game/singles_ms)::dec,'FM999999999.00')::dec park_factor_singles,
       to_char(float8 (doubles_per_game/doubles_ms)::dec,'FM999999999.00')::dec park_factor_doubles,
       to_char(float8 (triples_per_game/triples_ms)::dec,'FM999999999.00')::dec park_factor_triples,
       to_char(float8 (hr_per_game/homers_ms)::dec,'FM999999999.00')::dec park_factor_homers,
       0 as park_factor_starhits
       --to_char(float8 (star_hits_per_game/starhits_ms)::dec,'FM999999999.00')::dec park_factor_starhits
 from(

 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game,

       b.runs_per_game runs_per_game_ms,
       b.singles_per_game singles_ms,
       b.doubles_per_game doubles_ms,
       b.triples_per_game triples_ms,
       b.hr_per_game homers_ms,
       b.star_hits_per_game starhits_ms

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9bigballa'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id


)a

--select * from character_game_summary where game_id ='245171094785'

cross join 
(select stadium_name mario_stadium_value, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game
 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9bigballa'

                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
)a
where lower(stadium_name)= 'mario stadium'
group by 1
)b
 group by 1,8,9,10,11,12,13
order by runs_per_game
)c
group by 1,
runs_per_game, runs_per_game_ms,
singles_per_game, singles_ms,
doubles_per_game, doubles_ms,
triples_per_game, triples_ms,
hr_per_game, homers_ms
--star_hits_per_game, starhits_ms
)tbl
cross join
(select 's9bigballa' as gametype, 'park factor' as metric) gt

UNION

select * from (
select stadium_name,
       to_char(float8 (runs_per_game/runs_per_game_ms)::dec,'FM999999999.00')::dec park_factor_runs,
       to_char(float8 (singles_per_game/singles_ms)::dec,'FM999999999.00')::dec park_factor_singles,
       to_char(float8 (doubles_per_game/doubles_ms)::dec,'FM999999999.00')::dec park_factor_doubles,
       to_char(float8 (triples_per_game/triples_ms)::dec,'FM999999999.00')::dec park_factor_triples,
       to_char(float8 (hr_per_game/homers_ms)::dec,'FM999999999.00')::dec park_factor_homers,
       to_char(float8 (star_hits_per_game/starhits_ms)::dec,'FM999999999.00')::dec park_factor_starhits
 from(

 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game,

       b.runs_per_game runs_per_game_ms,
       b.singles_per_game singles_ms,
       b.doubles_per_game doubles_ms,
       b.triples_per_game triples_ms,
       b.hr_per_game homers_ms,
       b.star_hits_per_game starhits_ms

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarsoffhazards'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id

)a

--select * from character_game_summary where game_id ='245171094785'

cross join 
(select stadium_name mario_stadium_value, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game
 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarsoffhazards'

                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
)a
where lower(stadium_name)= 'mario stadium'
group by 1
)b
 group by 1,8,9,10,11,12,13
order by runs_per_game
)c
group by 1,
runs_per_game, runs_per_game_ms,
singles_per_game, singles_ms,
doubles_per_game, doubles_ms,
triples_per_game, triples_ms,
hr_per_game, homers_ms,
star_hits_per_game, starhits_ms
)tbl
cross join
(select 's9superstarsoffhazards' as gametype, 'park factor' as metric) gt


UNION

select * from (
 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarson'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
) a 
 group by 1
) tbl
 cross join 
(select 's9superstarson' as gametype, 'average value' as metric) gt

UNION

select * from (
 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarson'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
) a 
 group by 1
) tbl
 cross join 
(select 's9superstarsoff' as gametype, 'average value' as metric) gt

UNION

select * from (
 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9bigballa'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
) a 
 group by 1
) tbl
 cross join 
(select 's9bigballa' as gametype, 'average value' as metric) gt

UNION

select * from (
 select stadium_name, 
       to_char(float8 (sum(a.away_score+a.home_score))::dec/count(distinct a.game_id),'FM999999999.00')::dec runs_per_game,
       to_char(float8 (sum(a.singles))::dec/count(distinct a.game_id),'FM999999999.00')::dec singles_per_game,
       to_char(float8 (sum(a.doubles))::dec/count(distinct a.game_id),'FM999999999.00')::dec doubles_per_game,
       to_char(float8 (sum(a.triples))::dec/count(distinct a.game_id),'FM999999999.00')::dec triples_per_game,
       to_char(float8 (sum(a.homers))::dec/count(distinct a.game_id),'FM999999999.00')::dec hr_per_game,
       to_char(float8 (sum(a.starhits))::dec/count(distinct a.game_id),'FM999999999.00')::dec star_hits_per_game

 from(
    select distinct
    case when ga.stadium_id::text ='0' then 'Mario Stadium'
        when ga.stadium_id::text ='1' then 'Bowsers Castle'
        when ga.stadium_id::text ='2' then 'Warios Palace'
        when ga.stadium_id::text ='3' then 'Yoshis Island'
        when ga.stadium_id::text ='4' then 'Peachs Garden'
        when ga.stadium_id::text ='5' then 'DKs Jungle'
        when ga.stadium_id::text ='6' then 'Toy Field'
        else 'unknown stadium name'
        end stadium_name,

        ga.away_score,
        ga.home_score,
        ga.game_id,
        sum(cgs2.singles) over(partition by cgs2.game_id order by cgs2.game_id) as singles,
        sum(cgs2.doubles) over(partition by cgs2.game_id order by cgs2.game_id) as doubles,
        sum(cgs2.triples) over(partition by cgs2.game_id order by cgs2.game_id) as triples,
        sum(cgs2.homeruns) over(partition by cgs2.game_id order by cgs2.game_id) as homers,
        sum(cgs2.star_hits) over(partition by cgs2.game_id order by cgs2.game_id) as starhits
    

                                from game ga
                                left join game_history gh on ga.game_id = gh.game_id
                                left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                                left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                                left join tag_set ts on gh.tag_set_id = ts.id
                                left join character_game_summary cgs2 on ga.game_id = cgs2.game_id
                                left join character ch on ch.char_id = cgs2.char_id
                            where ts.name_lowercase = 's9superstarsoffhazards'
                            
                            group by 1,2,3,4, cgs2.singles, cgs2.doubles, cgs2.triples, cgs2.homeruns, cgs2.star_hits, cgs2.game_id
) a 
 group by 1
) tbl
 cross join 
(select 's9superstarsoffhazards' as gametype, 'average value' as metric) gt
)final 
 join games_per_gametype gpg on final.stadium_name = gpg.stadium_name
                             and final.gametype = gpg.gametype
 order by stadium_name, gametype, metric