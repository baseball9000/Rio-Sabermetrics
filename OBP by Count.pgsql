 -- OBP by Count
 -- 8/24/24

select *, sum(occurrences) over(partition by name_lowercase, balls, strikes order by name_lowercase, balls, strikes) as denominator from(
select name_lowercase, 
balls, strikes, ab_result, count(*) occurrences
 from(
select name_lowercase, balls, strikes, event_num, 
COALESCE(result, one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, thirteen, fourteen, fifteen) as ab_result
from(
select *, 
case when result is null then lead(result,1) over (partition by name_lowercase order by event_num) end as one,
case when result is null then lead(result,2) over (partition by name_lowercase order by event_num) end as two,
case when result is null then lead(result,3) over (partition by name_lowercase order by event_num) end as three,
case when result is null then lead(result,4) over (partition by name_lowercase order by event_num) end as four,
case when result is null then lead(result,5) over (partition by name_lowercase order by event_num) end as five,
case when result is null then lead(result,6) over (partition by name_lowercase order by event_num) end as six,
case when result is null then lead(result,7) over (partition by name_lowercase order by event_num) end as seven,
case when result is null then lead(result,8) over (partition by name_lowercase order by event_num) end as eight,
case when result is null then lead(result,9) over (partition by name_lowercase order by event_num) end as nine,
case when result is null then lead(result,10) over (partition by name_lowercase order by event_num) end as ten,
case when result is null then lead(result,11) over (partition by name_lowercase order by event_num) end as eleven,
case when result is null then lead(result,12) over (partition by name_lowercase order by event_num) end as twelve,
case when result is null then lead(result,13) over (partition by name_lowercase order by event_num) end as thirteen,
case when result is null then lead(result,14) over (partition by name_lowercase order by event_num) end as fourteen,
case when result is null then lead(result,15) over (partition by name_lowercase order by event_num) end as fifteen
from(
 select ch.name_lowercase, e.balls, e.strikes, e.game_id, e.event_num,
  max(case
    when e.result_of_ab = '2' then 'on base' --walk
    when e.result_of_ab = '3' then 'on base' --walk
    when e.result_of_ab = '7' then 'on base' --single
    when e.result_of_ab = '8' then 'on base' --double
    when e.result_of_ab = '9' then 'on base' --triple
    when e.result_of_ab = '10' then 'on base' --HR
    when e.result_of_ab = '11' then 'on base' --error
    when e.result_of_ab = '12' then 'on base' --error
    when e.result_of_ab in('1', '4', '5', '6', '15', '16') then 'out'
    --else e.result_of_ab::text
    end) over (partition by ch.name_lowercase, e.game_id, e.away_score, e.home_score order by e.event_num asc) result

 from event e 
  left join game g on g.game_id = e.game_id
  left join game_history gh on g.game_id = gh.game_id
  left join tag_set ts on gh.tag_set_id = ts.id
  left join character_game_summary cgs on e.batter_id = cgs.id
  left join character ch on ch.char_id = cgs.char_id
 --where e.game_id in('163902273584', '18641146132')
  where ts.name_lowercase in (
'starsoffseason6',
 'starsoffseason7',
 'starsoffseason8',
 's9superstarsoff'
)
 order by e.game_id, e.event_num asc
)tbl
order by event_num
)tbl2
)final 
where ab_result is not null
group by 1,2,3,4
order by name_lowercase, strikes, balls
)actual_final_lol 
group by 1,2,3,4,5
order by name_lowercase, strikes, balls