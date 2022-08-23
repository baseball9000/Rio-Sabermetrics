-- Run Expectancy Matrix, Linear Weights and wOBA
-- @thanners8647 on discord
-- 8/11/2022-8/23/2022
-- Project Rio for Mario Superstar Baseball for the Nintendo Gamecube

-- ###############################
-- ###############################

-- ***** Run Expectancy Matrix (aka RE24) *******************************
-- Creating this allows us to determine the expected run value of a specific state of the game, such as having runners on 1st and 2nd with 1 out.
-- **********************************************************************


-- ***** Linear Weights *************************************************
-- The goal of this analysis is to determine the expected run value of a specific result of an at-bat.  
-- Results being analyzed are outs, walks, reach base on error (rboe), single, double, triple, and HR
-- **********************************************************************

-- ***** wOBA ***********************************************************
-- At a league wide level, these values can be used to create the wOBA scale value to create wOBA
-- We can then analyze player-characters by this metric
-- wOBA (Fangraphs): A rate statistic which attempts to credit a hitter for the value of each outcome (weighted on the likelihood it will create runs) rather than treating all hits or times on base equally.
--       wOBA is on the same scale as OBP and is a better representation of offensive value than batting average, RBI, or OPS.
--       (a*BB)+(b*RBOE)+(c*1B)+(d*2B)+(e*3B)+(f*HR) / PA where outs or these events occur (simplified for mario baseball -- we cannot track unintentional walks)


-- ###############################
-- ###############################


-- ***** Creation of the advanced_stats table ***************************
-- The values that this query creates are stored in the advanced_stats table to create wRC+, uWRC+, and ucWRC+ values.




-- start


------------------------------------------------------------
-- STARS OFF
------------------------------------------------------------

-- create table holding values for total runs scored per half inning of each game
-- the top half of this union grabs the runs scored for the away team, the bottom half grabs the home team

DROP TABLE IF EXISTS runs_per_half_inning;
CREATE TEMPORARY TABLE runs_per_half_inning AS

select e.game_id,
       e.inning,
       case 
       when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name,
       coalesce((max(e.away_score))-(lag(max(e.away_score), 1) over (PARTITION BY e.game_id order by e.inning)), max(e.away_score)) as runs_in_inning
 from event e 
  left join game g on g.game_id = e.game_id
  left join (select gt.game_id,
                    string_agg(ta.name_lowercase::text, ', ') as tag_names,
                    string_agg(gt.tag_id::text, ', ') as tag_ids
             from game_tag gt 
              left join tag ta on gt.tag_id = ta.id
    group by 1) gt on g.game_id = gt.game_id
 where lower(g.ranked::text)='true'                                                         -- 300
  and (lower(gt.tag_names) like '%normal%' and lower(gt.tag_names) not like '%superstar%')  -- 301
  --and (lower(tag_names) like '%superstar%')                                               -- 301
  and half_inning ='0'
  and inning <'9' -- RE24 only looks at innings 1-8 per Tom Tango
group by 1,2,3

UNION

select e.game_id, 
       e.inning, 
       case 
       when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name, 
       coalesce((max(e.home_score))-(lag(max(e.home_score), 1) over (PARTITION BY e.game_id order by e.inning)), max(e.home_score)) as runs_in_inning
 from event e 
  left join game g on g.game_id = e.game_id
  left join (select gt.game_id,
                    string_agg(ta.name_lowercase::text, ', ') as tag_names,
                    string_agg(gt.tag_id::text, ', ') as tag_ids
            from game_tag gt 
             left join tag ta on  gt.tag_id = ta.id
    group by 1) gt on g.game_id = gt.game_id
 where lower(g.ranked::text)='true'                                                         -- 300
  and (lower(gt.tag_names) like '%normal%' and lower(gt.tag_names) not like '%superstar%')  -- 301
  --and (lower(tag_names) like '%superstar%')                                               -- 301
  and half_inning ='1'
  and inning <'9' -- RE24 only looks at innings 1-8 per Tom Tango
group by 1,2,3
order by game_id, inning, half_inning_name desc
;

-- create table holding occurrences of each base-out-state and the numbers of runs that have been scored in each half inning at the time of that BSO
-- the large case statement in this table translates each base-out-state to a numeric value


DROP TABLE IF EXISTS base_out_state_aggregate;
CREATE TEMPORARY TABLE base_out_state_aggregate AS

     select
       case when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '1'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '2'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '3'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '4'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '5'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '6'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '7'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '8'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '9'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '10'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '11'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '12'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '13'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '14'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '15'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '16'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '17'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '18'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '19'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '20'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '21'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '22'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '23'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '24'
            end base_out_state,

        game_id,
        away_score,
        home_score,
        inning,
        half_inning_name,
        event_num,
        runs_so_far_hi


            from(
            select distinct game_id,
                            away_score,
                            home_score,
                            case when half_inning ='0' then away_score-(min(away_score) over (partition by game_id, inning, half_inning order by event_num))
                            when half_inning ='1' then home_score-(min(home_score) over (partition by game_id, inning, half_inning order by event_num))
                            end runs_so_far_hi,
                            inning,
                            case when half_inning ='0' then 'top' when half_inning ='1' then 'bottom' end half_inning_name,
                            event_num,
                            outs,
                            case when runner_on_1 is not null then '1' else '0' end runner_on_1st,
                            case when runner_on_2 is not null then '1' else '0' end runner_on_2nd,
                            case when runner_on_3 is not null then '1' else '0' end runner_on_3rd

                    from event 
                    order by event_num asc
                         )a 
                         order by event_num asc
                    ;


-- get value for each base out state (BOS)
-- finding the difference in the total runs that occured in the inning to the runs that have occured since a BOS event gives a value to a BOS event.
-- if a runner on 1st with 0 outs BOS event occurs when 1 run has already scored in an inning, then the inning ends with 3 runs scored, that specific BOS event is given 2 runs
-- the count of each BOS event occurrence is then divided by the sum of the run value that it gained across all of its events

DROP TABLE IF EXISTS rematrix_values;
CREATE TEMPORARY TABLE rematrix_values AS
    select base_out_state id,
           bos_value_agg::decimal/cnt::decimal re_value
    from(
    select distinct
        base_out_state,
        count(base_out_state) cnt,
        sum(
        case when half_inning_name ='top' then runs_in_inning-runs_so_far_hi 
             when half_inning_name ='bottom' then runs_in_inning-runs_so_far_hi 
        end
        ) bos_value_agg

            from(
                select bosa.*, rphi.runs_in_inning
                    from base_out_state_aggregate as bosa
                       join runs_per_half_inning as rphi
                        on rphi.game_id = bosa.game_id
                        and rphi.inning = bosa.inning
                        and rphi.half_inning_name = bosa.half_inning_name
        order by event_num asc
        )a
        group by 1
        )b
        group by 1, bos_value_agg, cnt;



-- ###############################

-- Linear weights
-- finding each time a specific event happens, then averaging out its value based on the RE24 matrix

drop table if exists linear_weights;
create temp table linear_weights as

select result_of_ab_named, ab_agg_value::decimal/cnt_ab_type::decimal re_value_of_ab_result_type from( -- 5: this statement divides the total value into the occurrences from statement 4 to get a final AB result linear weight
select result_of_ab_named, sum(ab_result_re_value) ab_agg_value, count(result_of_ab_named) cnt_ab_type from( -- 4: this statement shows the sum of the ER values and the number of occurrences that the AB result had
select result_of_ab_named, nb_re_value::decimal-re_value::decimal+result_rbi::decimal ab_result_re_value from ( -- 3: this statement associates results of ABs with the ER value they provided
select b.*, rev.re_value::text, 
coalesce(lead(rev.re_value, 1) over(partition by b.game_id, b.inning, b.half_inning_name order by event_num asc), '0') nb_re_value
from( -- 2: this query assigns values to the base out states 
select
        game_id,
        inning,
        half_inning_name,
       case when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '1'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '2'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '3'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '4'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '5'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '6'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '7'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '8'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '9'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '10'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '11'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '12'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '13'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '14'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '15'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '16'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '17'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '18'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '19'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '20'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '21'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '22'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '23'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '24'
            end base_out_state,
        result_of_ab_named,
        result_rbi,
        away_score,
        home_score,
        event_num
            from( -- 1: this innermost query finds the game state and the result of the AB
            select distinct e.game_id,
                            e.away_score,
                            e.home_score,
                            e.inning,
                            case when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name,
                            e.event_num,
                            case
                            when e.result_of_ab = '2' then 'walk'
                            when e.result_of_ab = '3' then 'walk'
                            when e.result_of_ab = '7' then 'single'
                            when e.result_of_ab = '8' then 'double'
                            when e.result_of_ab = '9' then 'triple'
                            when e.result_of_ab = '10' then 'HR'
                            when e.result_of_ab = '11' then 'rboe'
                            when e.result_of_ab = '12' then 'rboe'
                            when e.result_of_ab in('1', '4', '5', '6', '15', '16') then 'out'
                            end result_of_ab_named,
                            e.result_rbi,
                            e.outs,
                            case when e.runner_on_1 is not null then '1' else '0' end runner_on_1st,
                            case when e.runner_on_2 is not null then '1' else '0' end runner_on_2nd,
                            case when e.runner_on_3 is not null then '1' else '0' end runner_on_3rd

                    from event e
                     left join game ga
                      on e.game_id = ga.game_id
                     left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                       from game_tag gt left join tag ta on  gt.tag_id = ta.id
                       group by 1) gt on ga.game_id = gt.game_id

                    where lower(ranked::text) ='true'                                                       -- 300
                    and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')      -- 301
                    --and (lower(tag_names) like '%superstar%')                                             -- 301
                    order by e.event_num asc
                         )a 
                         where result_of_ab_named is not null
                         order by event_num asc
)b
left join rematrix_values rev
on rev.id::text = b.base_out_state::text
order by event_num
)c
)d group by 1
)e group by 1, ab_agg_value, cnt_ab_type
;

--##############################################################################
-- adjust the linear weights to make the value of an out 0
-- this is one step of the normalization to OBP (an out is worth 0 obp points)

drop table if exists linear_weights_out_adj;
create temp table linear_weights_out_adj as
select
case when result_of_ab_named ='out' then re_value_of_ab_result_type
end adjustment
from linear_weights;

drop table if exists linear_weights_adj;
create temp table linear_weights_adj as
select result_of_ab_named, adj_value from(
select result_of_ab_named, 
re_value_of_ab_result_type::decimal-adjustment::decimal adj_value
from linear_weights
cross join linear_weights_out_adj
)a where adj_value is not null;




--##############################################################################
--**** Query to hold league OBP value

drop table if exists league_obp;
create temp table league_obp as
select total_on_base_events/all_abs::decimal obp from(
select 
sum(case when result_of_ab_named not in ('out', 'caught(anything)', 'caught(LD)', 'strikeout', 'gidp', 'foul catch')  then result_count end) total_on_base_events,
sum(result_count) all_abs
from(
select 
case
when e.result_of_ab in ('2', '3') then 'walk'
when e.result_of_ab = '7' then 'single'
when e.result_of_ab = '8' then 'double'
when e.result_of_ab = '9' then 'triple'
when e.result_of_ab = '10' then 'HR'
when e.result_of_ab in ('11', '12') then 'rboe'
when e.result_of_ab in ('1') then 'strikeout'
when e.result_of_ab in ('4') then 'out'
when e.result_of_ab in ('5') then 'caught(anything)'
when e.result_of_ab in ('6') then 'caught(LD)'
when e.result_of_ab in ('15') then 'gidp'
when e.result_of_ab in ('16') then 'foul catch'
end result_of_ab_named,
count(*) result_count

from event e
left join game ga
on e.game_id = ga.game_id
left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
from game_tag gt left join tag ta on  gt.tag_id = ta.id
group by 1) gt on ga.game_id = gt.game_id

where lower(ranked::text) ='true'                                                       -- 300
and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')      -- 301
--and (lower(tag_names) like '%superstar%')                                             -- 301

group by 1
order by result_count desc
)a where result_of_ab_named is not null
)b;

--##############################################################################
--**** Query to hold league unadjusted wOBA value (to create 'wOBA scale' normalization value)

drop table if exists unadjusted_league_woba;
create temp table unadjusted_league_woba as
select 
sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
select
a.result_of_ab_named, a.result_count, lwa.adj_value*a.result_count agg_value_of_ab_result from(
select 
case
when e.result_of_ab in ('2', '3') then 'walk'
when e.result_of_ab = '7' then 'single'
when e.result_of_ab = '8' then 'double'
when e.result_of_ab = '9' then 'triple'
when e.result_of_ab = '10' then 'HR'
when e.result_of_ab in ('11', '12') then 'rboe'
when e.result_of_ab in ('1', '4', '5', '6', '15', '16') then 'out'
end result_of_ab_named,
count(*) result_count

from event e

        left join game ga
         on e.game_id = ga.game_id
        left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
        group by 1) gt on ga.game_id = gt.game_id

    where lower(ranked::text) ='true'                                                       -- 300
     and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')     -- 301
     --and (lower(tag_names) like '%superstar%')                                            -- 301

group by 1) a
left join linear_weights_adj lwa
on a.result_of_ab_named = lwa.result_of_ab_named
where a.result_of_ab_named is not null 
)b;

--##############################################################################
--**** Query to hold wOBA Scale value
-- 2nd step of wOBA normalization

drop table if exists woba_scale;
create temp table woba_scale as
select obp.obp::decimal/uw.unadj_woba::decimal as woba_scale
from league_obp obp cross join unadjusted_league_woba uw
;

--##############################################################################
--**** Calculate a character, RioUser, or RioUser-character's wOBA

drop table if exists woba;
create temp table woba as
select 
(unadj_woba::decimal*ws.woba_scale::decimal) woba from (
    select 
    sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
        select 
        a.result_of_ab_named, a.result_count, lwa.adj_value*a.result_count agg_value_of_ab_result from(
            select
            case
            when e.result_of_ab in ('2', '3') then 'walk'
            when e.result_of_ab = '7' then 'single'
            when e.result_of_ab = '8' then 'double'
            when e.result_of_ab = '9' then 'triple'
            when e.result_of_ab = '10' then 'HR'
            when e.result_of_ab in ('11', '12') then 'rboe'
            when e.result_of_ab in ('1', '4', '5', '6', '15', '16') then 'out'
            end result_of_ab_named,
            count(*) result_count

            from event e

                    left join game ga
                    on e.game_id = ga.game_id
                    left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                                from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                    left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                    left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                    left join character_game_summary cgs on cgs.id = e.batter_id
                    left join character ch on ch.char_id = cgs.char_id
                where lower(ranked::text) ='true'                                                                                                       -- 300
                 and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')                                                   -- 301
                -- and (lower(tag_names) like '%superstar%')                                                                                               -- 301
                -- and ((e.half_inning ='0' and awayru.away_username ='thanners') or (e.half_inning ='1' and homeru.home_username ='thanners'))         -- 302
                -- and ch.name_lowercase ='bowser'                                                                                                      -- 303
                -- and lower(cgs.batting_hand::text) ='true'                                                                                            -- 304


            group by 1
            )a
left join linear_weights_adj lwa
on a.result_of_ab_named = lwa.result_of_ab_named
where a.result_of_ab_named is not null 
)b
)c
cross join woba_scale ws
group by 
unadj_woba, woba_scale
;


--------################### finding runs per plate appearance for all players
drop table if exists runs_per_pa;
create temp table runs_per_pa as
select sum(runs)::dec/sum(total_pa)::dec runs_per_pa from(
select 
a.game_id,
sum(distinct ga.away_score+ga.home_score) runs,
sum(case when result_of_ab not in ('0') then
1 else 0 end) total_pa
from(
            select distinct 
                            e.id,
                            e.game_id,
                            e.away_score,
                            e.home_score,
                            e.inning,
                            case when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name,
                            e.event_num,
                            e.result_of_ab::text,
                            e.result_rbi,
                            e.outs

                    from event e
                     left join game ga
                      on e.game_id = ga.game_id
                     left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                       from game_tag gt left join tag ta on  gt.tag_id = ta.id
                       group by 1) gt on ga.game_id = gt.game_id

                    where lower(ranked::text) ='true'
                    and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                    --and (lower(tag_names) like '%superstar%')
                      order by e.event_num asc
                    )a 
                    left join game ga on ga.game_id = a.game_id
                    where result_of_ab is not null
                    group by 1
                    )b;







------------------------------------------------------------
-- STARS ON
------------------------------------------------------------







DROP TABLE IF EXISTS runs_per_half_inning_stars_on;
CREATE TEMPORARY TABLE runs_per_half_inning_stars_on AS

select e.game_id,
       e.inning,
       case 
       when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name,
       coalesce((max(e.away_score))-(lag(max(e.away_score), 1) over (PARTITION BY e.game_id order by e.inning)), max(e.away_score)) as runs_in_inning
 from event e 
  left join game g on g.game_id = e.game_id
  left join (select gt.game_id,
                    string_agg(ta.name_lowercase::text, ', ') as tag_names,
                    string_agg(gt.tag_id::text, ', ') as tag_ids
             from game_tag gt 
              left join tag ta on gt.tag_id = ta.id
    group by 1) gt on g.game_id = gt.game_id
 where lower(g.ranked::text)='true'                                                         -- 300
  --and (lower(gt.tag_names) like '%normal%' and lower(gt.tag_names) not like '%superstar%')  -- 301
  and (lower(tag_names) like '%superstar%')                                               -- 301
  and half_inning ='0'
  and inning <'9' -- RE24 only looks at innings 1-8 per Tom Tango
group by 1,2,3

UNION

select e.game_id, 
       e.inning, 
       case 
       when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name, 
       coalesce((max(e.home_score))-(lag(max(e.home_score), 1) over (PARTITION BY e.game_id order by e.inning)), max(e.home_score)) as runs_in_inning
 from event e 
  left join game g on g.game_id = e.game_id
  left join (select gt.game_id,
                    string_agg(ta.name_lowercase::text, ', ') as tag_names,
                    string_agg(gt.tag_id::text, ', ') as tag_ids
            from game_tag gt 
             left join tag ta on  gt.tag_id = ta.id
    group by 1) gt on g.game_id = gt.game_id
 where lower(g.ranked::text)='true'                                                         -- 300
  --and (lower(gt.tag_names) like '%normal%' and lower(gt.tag_names) not like '%superstar%')  -- 301
  and (lower(tag_names) like '%superstar%')                                               -- 301
  and half_inning ='1'
  and inning <'9' -- RE24 only looks at innings 1-8 per Tom Tango
group by 1,2,3
order by game_id, inning, half_inning_name desc
;

-- create table holding occurrences of each base-out-state and the numbers of runs that have been scored in each half inning at the time of that BSO
-- the large case statement in this table translates each base-out-state to a numeric value


DROP TABLE IF EXISTS base_out_state_aggregate_stars_on;
CREATE TEMPORARY TABLE base_out_state_aggregate_stars_on AS

     select
       case when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '1'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '2'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '3'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '4'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '5'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '6'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '7'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '8'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '9'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '10'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '11'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '12'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '13'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '14'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '15'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '16'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '17'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '18'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '19'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '20'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '21'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '22'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '23'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '24'
            end base_out_state,

        game_id,
        away_score,
        home_score,
        inning,
        half_inning_name,
        event_num,
        runs_so_far_hi


            from(
            select distinct game_id,
                            away_score,
                            home_score,
                            case when half_inning ='0' then away_score-(min(away_score) over (partition by game_id, inning, half_inning order by event_num))
                            when half_inning ='1' then home_score-(min(home_score) over (partition by game_id, inning, half_inning order by event_num))
                            end runs_so_far_hi,
                            inning,
                            case when half_inning ='0' then 'top' when half_inning ='1' then 'bottom' end half_inning_name,
                            event_num,
                            outs,
                            case when runner_on_1 is not null then '1' else '0' end runner_on_1st,
                            case when runner_on_2 is not null then '1' else '0' end runner_on_2nd,
                            case when runner_on_3 is not null then '1' else '0' end runner_on_3rd

                    from event 
                    order by event_num asc
                         )a 
                         order by event_num asc
                    ;


-- get value for each base out state (BOS)
-- finding the difference in the total runs that occured in the inning to the runs that have occured since a BOS event gives a value to a BOS event.
-- if a runner on 1st with 0 outs BOS event occurs when 1 run has already scored in an inning, then the inning ends with 3 runs scored, that specific BOS event is given 2 runs
-- the count of each BOS event occurrence is then divided by the sum of the run value that it gained across all of its events

DROP TABLE IF EXISTS rematrix_values_stars_on;
CREATE TEMPORARY TABLE rematrix_values_stars_on AS
    select base_out_state id,
           bos_value_agg::decimal/cnt::decimal re_value
    from(
    select distinct
        base_out_state,
        count(base_out_state) cnt,
        sum(
        case when half_inning_name ='top' then runs_in_inning-runs_so_far_hi 
             when half_inning_name ='bottom' then runs_in_inning-runs_so_far_hi 
        end
        ) bos_value_agg

            from(
                select bosa.*, rphi.runs_in_inning
                    from base_out_state_aggregate_stars_on as bosa
                       join runs_per_half_inning_stars_on as rphi
                        on rphi.game_id = bosa.game_id
                        and rphi.inning = bosa.inning
                        and rphi.half_inning_name = bosa.half_inning_name
        order by event_num asc
        )a
        group by 1
        )b
        group by 1, bos_value_agg, cnt;



-- ###############################

-- Linear weights
-- finding each time a specific event happens, then averaging out its value based on the RE24 matrix

drop table if exists linear_weights_stars_on;
create temp table linear_weights_stars_on as

select result_of_ab_named, ab_agg_value::decimal/cnt_ab_type::decimal re_value_of_ab_result_type from( -- 5: this statement divides the total value into the occurrences from statement 4 to get a final AB result linear weight
select result_of_ab_named, sum(ab_result_re_value) ab_agg_value, count(result_of_ab_named) cnt_ab_type from( -- 4: this statement shows the sum of the ER values and the number of occurrences that the AB result had
select result_of_ab_named, nb_re_value::decimal-re_value::decimal+result_rbi::decimal ab_result_re_value from ( -- 3: this statement associates results of ABs with the ER value they provided
select b.*, rev.re_value::text, 
coalesce(lead(rev.re_value, 1) over(partition by b.game_id, b.inning, b.half_inning_name order by event_num asc), '0') nb_re_value
from( -- 2: this query assigns values to the base out states 
select
        game_id,
        inning,
        half_inning_name,
       case when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '1'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '2'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='0' then '3'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '4'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '5'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='0' then '6'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '7'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '8'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='0' then '9'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '10'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '11'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='0' then '12'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '13'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '14'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='0' and runner_on_3rd ='1' then '15'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '16'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '17'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='0' and runner_on_3rd ='1' then '18'
            when outs ='0' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '19'
            when outs ='1' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '20'
            when outs ='2' and runner_on_1st ='0' and runner_on_2nd ='1' and runner_on_3rd ='1' then '21'
            when outs ='0' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '22'
            when outs ='1' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '23'
            when outs ='2' and runner_on_1st ='1' and runner_on_2nd ='1' and runner_on_3rd ='1' then '24'
            end base_out_state,
        result_of_ab_named,
        result_rbi,
        away_score,
        home_score,
        event_num
            from( -- 1: this innermost query finds the game state and the result of the AB
            select distinct e.game_id,
                            e.away_score,
                            e.home_score,
                            e.inning,
                            case when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name,
                            e.event_num,
                            case
                            when e.result_of_ab = '2' then 'walk'
                            when e.result_of_ab = '3' then 'walk'
                            when e.result_of_ab = '7' then 'single'
                            when e.result_of_ab = '8' then 'double'
                            when e.result_of_ab = '9' then 'triple'
                            when e.result_of_ab = '10' then 'HR'
                            when e.result_of_ab = '11' then 'rboe'
                            when e.result_of_ab = '12' then 'rboe'
                            when e.result_of_ab in('1', '4', '5', '6', '15', '16') then 'out'
                            end result_of_ab_named,
                            e.result_rbi,
                            e.outs,
                            case when e.runner_on_1 is not null then '1' else '0' end runner_on_1st,
                            case when e.runner_on_2 is not null then '1' else '0' end runner_on_2nd,
                            case when e.runner_on_3 is not null then '1' else '0' end runner_on_3rd

                    from event e
                     left join game ga
                      on e.game_id = ga.game_id
                     left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                       from game_tag gt left join tag ta on  gt.tag_id = ta.id
                       group by 1) gt on ga.game_id = gt.game_id

                    where lower(ranked::text) ='true'                                                       -- 300
                    --and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')      -- 301
                    and (lower(tag_names) like '%superstar%')                                             -- 301
                    order by e.event_num asc
                         )a 
                         where result_of_ab_named is not null
                         order by event_num asc
)b
left join rematrix_values_stars_on rev
on rev.id::text = b.base_out_state::text
order by event_num
)c
)d group by 1
)e group by 1, ab_agg_value, cnt_ab_type
;

--##############################################################################
-- adjust the linear weights to make the value of an out 0
-- this is one step of the normalization to OBP (an out is worth 0 obp points)

drop table if exists linear_weights_out_adj_stars_on;
create temp table linear_weights_out_adj_stars_on as
select
case when result_of_ab_named ='out' then re_value_of_ab_result_type
end adjustment
from linear_weights_stars_on;

drop table if exists linear_weights_adj_stars_on;
create temp table linear_weights_adj_stars_on as
select result_of_ab_named, adj_value from(
select result_of_ab_named, 
re_value_of_ab_result_type::decimal-adjustment::decimal adj_value
from linear_weights_stars_on
cross join linear_weights_out_adj_stars_on
)a where adj_value is not null;




--##############################################################################
--**** Query to hold league OBP value

drop table if exists league_obp_stars_on;
create temp table league_obp_stars_on as
select total_on_base_events/all_abs::decimal obp from(
select 
sum(case when result_of_ab_named not in ('out', 'caught(anything)', 'caught(LD)', 'strikeout', 'gidp', 'foul catch')  then result_count end) total_on_base_events,
sum(result_count) all_abs
from(
select 
case
when e.result_of_ab in ('2', '3') then 'walk'
when e.result_of_ab = '7' then 'single'
when e.result_of_ab = '8' then 'double'
when e.result_of_ab = '9' then 'triple'
when e.result_of_ab = '10' then 'HR'
when e.result_of_ab in ('11', '12') then 'rboe'
when e.result_of_ab in ('1') then 'strikeout'
when e.result_of_ab in ('4') then 'out'
when e.result_of_ab in ('5') then 'caught(anything)'
when e.result_of_ab in ('6') then 'caught(LD)'
when e.result_of_ab in ('15') then 'gidp'
when e.result_of_ab in ('16') then 'foul catch'
end result_of_ab_named,
count(*) result_count

from event e
left join game ga
on e.game_id = ga.game_id
left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
from game_tag gt left join tag ta on  gt.tag_id = ta.id
group by 1) gt on ga.game_id = gt.game_id

where lower(ranked::text) ='true'                                                       -- 300
--and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')      -- 301
and (lower(tag_names) like '%superstar%')                                             -- 301

group by 1
order by result_count desc
)a where result_of_ab_named is not null
)b;

--##############################################################################
--**** Query to hold league unadjusted wOBA value (to create 'wOBA scale' normalization value)

drop table if exists unadjusted_league_woba_stars_on;
create temp table unadjusted_league_woba_stars_on as
select 
sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
select
a.result_of_ab_named, a.result_count, lwa.adj_value*a.result_count agg_value_of_ab_result from(
select 
case
when e.result_of_ab in ('2', '3') then 'walk'
when e.result_of_ab = '7' then 'single'
when e.result_of_ab = '8' then 'double'
when e.result_of_ab = '9' then 'triple'
when e.result_of_ab = '10' then 'HR'
when e.result_of_ab in ('11', '12') then 'rboe'
when e.result_of_ab in ('1', '4', '5', '6', '15', '16') then 'out'
end result_of_ab_named,
count(*) result_count

from event e

        left join game ga
         on e.game_id = ga.game_id
        left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
        group by 1) gt on ga.game_id = gt.game_id

    where lower(ranked::text) ='true'                                                       -- 300
     --and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')     -- 301
     and (lower(tag_names) like '%superstar%')                                            -- 301

group by 1) a
left join linear_weights_adj_stars_on lwa
on a.result_of_ab_named = lwa.result_of_ab_named
where a.result_of_ab_named is not null 
)b;

--##############################################################################
--**** Query to hold wOBA Scale value
-- 2nd step of wOBA normalization

drop table if exists woba_scale_stars_on;
create temp table woba_scale_stars_on as
select obp.obp::decimal/uw.unadj_woba::decimal as woba_scale
from league_obp_stars_on obp cross join unadjusted_league_woba_stars_on uw
;

--##############################################################################
--**** Calculate a character, RioUser, or RioUser-character's wOBA

drop table if exists woba_stars_on;
create temp table woba_stars_on as
select 
(unadj_woba::decimal*ws.woba_scale::decimal) woba from (
    select 
    sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
        select 
        a.result_of_ab_named, a.result_count, lwa.adj_value*a.result_count agg_value_of_ab_result from(
            select
            case
            when e.result_of_ab in ('2', '3') then 'walk'
            when e.result_of_ab = '7' then 'single'
            when e.result_of_ab = '8' then 'double'
            when e.result_of_ab = '9' then 'triple'
            when e.result_of_ab = '10' then 'HR'
            when e.result_of_ab in ('11', '12') then 'rboe'
            when e.result_of_ab in ('1', '4', '5', '6', '15', '16') then 'out'
            end result_of_ab_named,
            count(*) result_count

            from event e

                    left join game ga
                    on e.game_id = ga.game_id
                    left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                                from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                    left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                    left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                    left join character_game_summary cgs on cgs.id = e.batter_id
                    left join character ch on ch.char_id = cgs.char_id
                where lower(ranked::text) ='true'                                                                                                       -- 300
                -- and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')                                                   -- 301
                 and (lower(tag_names) like '%superstar%')                                                                                               -- 301
                -- and ((e.half_inning ='0' and awayru.away_username ='thanners') or (e.half_inning ='1' and homeru.home_username ='thanners'))         -- 302
                -- and ch.name_lowercase ='bowser'                                                                                                      -- 303
                -- and lower(cgs.batting_hand::text) ='true'                                                                                            -- 304


            group by 1
            )a
left join linear_weights_adj_stars_on lwa
on a.result_of_ab_named = lwa.result_of_ab_named
where a.result_of_ab_named is not null 
)b
)c
cross join woba_scale_stars_on ws
group by 
unadj_woba, woba_scale
;


--------################### finding runs per plate appearance for all players
drop table if exists runs_per_pa_stars_on;
create temp table runs_per_pa_stars_on as
select sum(runs)::dec/sum(total_pa)::dec runs_per_pa from(
select 
a.game_id,
sum(distinct ga.away_score+ga.home_score) runs,
sum(case when result_of_ab not in ('0') then
1 else 0 end) total_pa
from(
            select distinct 
                            e.id,
                            e.game_id,
                            e.away_score,
                            e.home_score,
                            e.inning,
                            case when e.half_inning ='0' then 'top' when e.half_inning ='1' then 'bottom' end half_inning_name,
                            e.event_num,
                            e.result_of_ab::text,
                            e.result_rbi,
                            e.outs

                    from event e
                     left join game ga
                      on e.game_id = ga.game_id
                     left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                       from game_tag gt left join tag ta on  gt.tag_id = ta.id
                       group by 1) gt on ga.game_id = gt.game_id

                    where lower(ranked::text) ='true'
                    --and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                    and (lower(tag_names) like '%superstar%')
                      order by e.event_num asc
                    )a 
                    left join game ga on ga.game_id = a.game_id
                    where result_of_ab is not null
                    group by 1
                    )b;








-----------------------------------------------------------------------------------------
-- cwOBA Starts Here
----------------------------------------------------------------------------------------








-- cwOBA Stars Off, all 54 characters
 

--##############################################################################
--**** Calculate a character, RioUser, or RioUser-character's wOBA
-- edits made on 8/18 to grab all characters
drop table if exists cwoba;
create temp table cwoba as
select c.name_lowercase, c.handedness,
(unadj_woba::decimal*ws.woba_scale::decimal) woba from (
    select b.name_lowercase, b.handedness,
    sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
        select a.name_lowercase, a.handedness,
        a.result_of_ab_named, a.result_count, lwa.adj_value*a.result_count agg_value_of_ab_result from(
            select
            ch.name_lowercase,
            case when lower(cgs.batting_hand::text)='true' then 'lefty' when lower(cgs.batting_hand::text)='false' then 'righty' end handedness,
            case
            when e.result_of_ab in ('2', '3') then 'walk'
            when e.result_of_ab = '7' then 'single'
            when e.result_of_ab = '8' then 'double'
            when e.result_of_ab = '9' then 'triple'
            when e.result_of_ab = '10' then 'HR'
            when e.result_of_ab in ('11', '12') then 'rboe'
            when e.result_of_ab in ('1', '4', '5', '6', '15', '16') then 'out'
            end result_of_ab_named,
            count(*) result_count

            from event e

                    left join game ga
                    on e.game_id = ga.game_id
                    left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                                from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                    left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                    left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                    left join character_game_summary cgs on cgs.id = e.batter_id
                    left join character ch on ch.char_id = cgs.char_id
                where lower(ranked::text) ='true'                                                                                                       -- 300
                and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')                                                      -- 301
                -- and (lower(tag_names) like '%superstar%')                                                                                            -- 301
                -- and ((e.half_inning ='0' and awayru.away_username ='thanners') or (e.half_inning ='1' and homeru.home_username ='thanners'))         -- 302
                -- and ch.name_lowercase ='bowser'                                                                                                       -- 303
                -- and lower(cgs.batting_hand::text) ='true'                                                                                            -- 304


            group by 1,2,3
            )a
left join linear_weights_adj lwa
on a.result_of_ab_named = lwa.result_of_ab_named
where a.result_of_ab_named is not null 
)b group by 1,2
)c
cross join woba_scale ws
group by 
name_lowercase, handedness, unadj_woba, woba_scale
;





-- cwOBA Stars On, all 54 characters
 

--##############################################################################
--**** Calculate a character, RioUser, or RioUser-character's wOBA
-- edits made on 8/18 to grab all characters
drop table if exists cwoba_stars_on;
create temp table cwoba_stars_on as
select c.name_lowercase, c.handedness,
(unadj_woba::decimal*ws.woba_scale::decimal) woba from (
    select b.name_lowercase, b.handedness,
    sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
        select a.name_lowercase, a.handedness,
        a.result_of_ab_named, a.result_count, lwa.adj_value*a.result_count agg_value_of_ab_result from(
            select
            ch.name_lowercase,
            case when lower(cgs.batting_hand::text)='true' then 'lefty' when lower(cgs.batting_hand::text)='false' then 'righty' end handedness,
            case
            when e.result_of_ab in ('2', '3') then 'walk'
            when e.result_of_ab = '7' then 'single'
            when e.result_of_ab = '8' then 'double'
            when e.result_of_ab = '9' then 'triple'
            when e.result_of_ab = '10' then 'HR'
            when e.result_of_ab in ('11', '12') then 'rboe'
            when e.result_of_ab in ('1', '4', '5', '6', '15', '16') then 'out'
            end result_of_ab_named,
            count(*) result_count

            from event e

                    left join game ga
                    on e.game_id = ga.game_id
                    left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                                from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                    left join (select distinct ru.id, ru.username_lowercase away_username from rio_user ru) awayru on awayru.id = ga.away_player_id
                    left join (select distinct ru.id, ru.username_lowercase home_username from rio_user ru) homeru on homeru.id = ga.home_player_id
                    left join character_game_summary cgs on cgs.id = e.batter_id
                    left join character ch on ch.char_id = cgs.char_id
                where lower(ranked::text) ='true'                                                                                                       -- 300
                -- and (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')                                                      -- 301
                 and (lower(tag_names) like '%superstar%')                                                                                            -- 301
                -- and ((e.half_inning ='0' and awayru.away_username ='thanners') or (e.half_inning ='1' and homeru.home_username ='thanners'))         -- 302
                -- and ch.name_lowercase ='bowser'                                                                                                       -- 303
                -- and lower(cgs.batting_hand::text) ='true'                                                                                            -- 304


            group by 1,2,3
            )a
left join linear_weights_adj_stars_on lwa
on a.result_of_ab_named = lwa.result_of_ab_named
where a.result_of_ab_named is not null 
)b group by 1,2
)c
cross join woba_scale_stars_on ws
group by 
name_lowercase, handedness, unadj_woba, woba_scale
;




---------------------------------------------------------------------
-- Creating advanced_stats table
---------------------------------------------------------------------

drop table if exists runs_per_pa_temp_off_final;
create temp table runs_per_pa_temp_off_final as
SELECT 'runs per pa'        as metric,
'off'                       as competition,
NULL                        as character,
NULL                        as metric_detail,
'wrc+'                      as stat_component_of,
runs_per_pa                 as value
from runs_per_pa;

drop table if exists runs_per_pa_temp_on_final;
create temp table runs_per_pa_temp_on_final as
SELECT 'runs per pa'        as metric,
'on'                        as competition,
NULL                        as character,
NULL                        as metric_detail,
'wrc+'                      as stat_component_of,
runs_per_pa                 as value
from runs_per_pa_stars_on;

drop table if exists woba_stars_off_temp_final;
create temp table woba_stars_off_temp_final as
select 'woba'               as metric,
'off'                       as competition,
NULL                        as character,
NULL                        as metric_detail,
'wrc+'                      as stat_component_of,
woba                        as value
from woba;

drop table if exists woba_stars_on_temp_final;
create temp table woba_stars_on_temp_final as
select 'woba'               as metric,
'on'                        as competition,
NULL                        as character,
NULL                        as metric_detail,
'wrc+'                      as stat_component_of,
woba                        as value
from woba_stars_on;

drop table if exists woba_scale_stars_off_temp_final;
create temp table woba_scale_stars_off_temp_final as
select 'woba scale'         as metric,
'off'                       as competition,
NULL                        as character,
NULL                        as metric_detail,
'wrc+'                      as stat_component_of,
woba_scale                  as value
from woba_scale;

drop table if exists woba_scale_stars_on_temp_final;
create temp table woba_scale_stars_on_temp_final as
select 'woba scale'         as metric,
'on'                        as competition,
NULL                        as character,
NULL                        as metric_detail,
'wrc+'                      as stat_component_of,
woba_scale                  as value
from woba_scale_stars_on;

drop table if exists cwoba_stars_off_temp_final;
create temp table cwoba_stars_off_temp_final as
select 'cwoba'              as metric,
'off'                       as competition,
name_lowercase              as character,
handedness                  as metric_detail,
'wrc+'                      as stat_component_of,
woba                        as value
from cwoba;

drop table if exists cwoba_stars_on_temp_final;
create temp table cwoba_stars_on_temp_final as
select 'cwoba'              as metric,
'on'                        as competition,
name_lowercase              as character,
handedness                  as metric_detail,
'wrc+'                      as stat_component_of,
woba                        as value
from cwoba_stars_on;

drop table if exists linear_weights_stars_on_temp_final;
create temp table linear_weights_stars_on_temp_final as
select 'linear weight'      as metric,
'on'                        as competition,
NULL                        as character,
result_of_ab_named          as metric_detail,
'wrc+'                      as stat_component_of,
adj_value                   as value
from linear_weights_adj_stars_on;

drop table if exists linear_weights_stars_off_temp_final;
create temp table linear_weights_stars_off_temp_final as
select 'linear weight'      as metric,
'off'                       as competition,
NULL                        as character,
result_of_ab_named          as metric_detail,
'wrc+'                      as stat_component_of,
adj_value                   as value
from linear_weights_adj;



------------------------------------------


drop table if exists advanced_stats;
create table advanced_stats as
select * from runs_per_pa_temp_off_final
union
select * from runs_per_pa_temp_on_final
union
select * from woba_stars_off_temp_final
union
select * from woba_stars_on_temp_final
union
select * from woba_scale_stars_off_temp_final
union
select * from woba_scale_stars_on_temp_final
union
select * from cwoba_stars_off_temp_final
union
select * from cwoba_stars_on_temp_final
union
select * from linear_weights_stars_on_temp_final
union
select * from linear_weights_stars_off_temp_final;
