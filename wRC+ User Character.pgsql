-- thanners#8647 on Discord

-- User-Character query -------------------------------------------------------------------------------
-- user would type in something like: %uwRC+ off thanners yoshi

-- insert parameters here -------------
with c as (select 'wario' as character
           --union select 'waluigi' as character
           --union select 'mario' as character
           --select name_lowercase as character from character
           ),
     u as (--select 'thanners' as user
           --union select 'mori' as user
           --union select 'pokebunny' as user
           select username_lowercase as user from rio_user),

     x as (select 'off' as competition),

     h as (select 'lefty' as handedness
           union select 'righty' as handedness),
---------------------------------------
-- don't edit below here --

     r as (select value from advanced_stats where lower(metric) = 'runs per pa' and competition =(select * from x)),

     lgcwoba_value_hold as
          (select character, metric_detail, value from advanced_stats
            where lower(competition) = (select * from x)                                         -- same thing here for 'off'
            and lower(metric) ='cwoba'
            and lower(character) in (select * from c)
            and lower(metric_detail) in (select * from h)),                                           -- same thing here for 'bowser'

     lgwobascale_value_hold as
          (select value from advanced_stats
            where lower(competition) = (select * from x)                                          -- same thing here for 'off'
            and lower(metric) ='woba scale'),

     user_character_value_hold as
          (select c.username_lowercase user, c.name_lowercase char_name, c.handedness,
            (unadj_woba::decimal*ws.woba_scale::decimal) value from(
                select b.username_lowercase, b.name_lowercase, b.handedness,
                sum(agg_value_of_ab_result)::decimal/sum(result_count)::decimal unadj_woba from(
                    select a.username_lowercase, a.name_lowercase, a.handedness,
                    a.result_of_ab_named, a.result_count, lwa.value*a.result_count agg_value_of_ab_result from(
                        select
                        cgs.username_lowercase,
                        case when lower(cgs.batting_hand::text)='true' then 'lefty' when lower(cgs.batting_hand::text)='false' then 'righty' end handedness,
                        ch.name_lowercase,
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
                                left join (select cgs.id, cgs.game_id, cgs.user_id, cgs.char_id, cgs.batting_hand, ru.username_lowercase from character_game_summary cgs 
                                           left join rio_user ru on cgs.user_id = ru.id) cgs on cgs.id = e.batter_id
                                left join character ch on ch.char_id = cgs.char_id
                            where lower(ranked::text) ='true'
                            and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                                     when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                                     end)
                            -- and ((e.half_inning ='0' and awayru.away_username =(select * from u)) or (e.half_inning ='1' and homeru.home_username =(select * from u)))
                            and cgs.username_lowercase in (select * from u)
                            and ch.name_lowercase in (select * from c)
                            and case when lower(cgs.batting_hand::text)='true' then 'lefty' when lower(cgs.batting_hand::text)='false' then 'righty' end in (select * from h)


                        group by 1,
                        2, -- parameterize
                        3, -- parameterize
                        4 -- parameterize
                        )a
            left join (select metric_detail, value from advanced_stats
                    where lower(metric) ='linear weight'
                    and lower(competition) =(select * from x)) lwa
            on a.result_of_ab_named = lwa.metric_detail
            where a.result_of_ab_named is not null 
            )b
            group by  -- parameterize
            1, -- parameterize
            2, -- parameterize
            3 -- parameterize
            having sum(result_count) >=30
            )c
            cross join (select value woba_scale from advanced_stats
                    where lower(metric) ='woba scale'
                    and lower(competition) =(select * from x)) ws
            group by 
            1, -- parameterize
            2, -- parameterize
            3, -- parameterize
            unadj_woba, woba_scale)

            
-- this entire thing needs to be parameterized

select 
f.user, f.char_name, f.handedness,-- parameterize
to_char(float8 ((((avalue-bvalue)/cvalue)/rvalue)+1)*100,'FM999999999.00')::dec wrcplus
from(
select a.user, a.char_name, a.handedness, a.value avalue, b.value bvalue, c.value cvalue, r.value rvalue
from user_character_value_hold a
left join lgcwoba_value_hold b
on a.char_name = b.character
and a.handedness = b.metric_detail
cross join lgwobascale_value_hold c
cross join r r 
)f
group by 1,2,3, avalue, bvalue, cvalue, rvalue -- parameterize
order by wrcplus desc
