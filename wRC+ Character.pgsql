-- thanners#8647 on Discord

-- Character query -------------------------------------------------------------------------------
-- user would type in something like: %cwRC+ off yoshi

-- insert parameters here ----------------------
with c as (select 'king boo' as character
           --union select 'boo' as character
           --union select 'luigi' as character
           --select name_lowercase as character from character
           ),
     x as (select 'off' as competition),
     h as (select 'lefty' as handedness
           union select 'righty' as handedness),
------------------------------------------------
-- don't edit below here --

r as (select value from advanced_stats where lower(metric) = 'runs per pa' and competition =(select * from x)),

character_value_hold as
(select character, metric_detail, value from advanced_stats 
where lower(competition) = (select * from x) -- parameterize
and lower(metric) = 'cwoba'
and lower(character) in (select * from c)
and lower(metric_detail) in (select * from h)), -- parameterize

lgwoba_value_hold as
(select value from advanced_stats
where lower(competition) = (select * from x) -- parameterize
and lower(metric) ='woba'),


lgwobascale_value_hold as
(select value from advanced_stats
where lower(competition) = (select * from x) -- parameterize
and lower(metric) ='woba scale')


select 
a.character, -- parameterize
a.metric_detail handedness,
to_char(float8 ((((a.value-b.value)/c.value)/r.value)+1)*100,'FM999999999.00')::dec wrcplus
from character_value_hold a 
cross join lgwoba_value_hold b 
cross join lgwobascale_value_hold c
cross join r r

-- adding join to get PA per character to make filter on.  no one cares to see purple toad in 5th place.
left join(
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
                                left join (select cgs.id, cgs.game_id, cgs.user_id, cgs.char_id, cgs.batting_hand, ru.username_lowercase from character_game_summary cgs 
                                           left join rio_user ru on cgs.user_id = ru.id) cgs on cgs.id = e.batter_id
                                left join character ch on ch.char_id = cgs.char_id
                            where lower(ranked::text) ='true'
                            and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                                     when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                                     end)
                                     group by 1,2,3) pa on pa.name_lowercase = a.character

group by 1,2, a.value, b.value, c.value, r.value -- parameterize
having sum(pa.result_count) > 300
order by wrcplus desc

;