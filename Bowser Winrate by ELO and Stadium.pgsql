-- bowser winrate by elo percentile and stadium --
-- thanners on discord
-- 4/5/24


-- bowser winrate without stadiums

 -- percentile
drop table if exists percentile_temp;
create temporary table percentile_temp as
select PERCENTILE_CONT(0.90) -- change this to select percentile
WITHIN GROUP(ORDER BY (winner_incoming_elo+loser_incoming_elo)/2) from game_history gh left join tag_set ts on gh.tag_set_id = ts.id
where ts.name_lowercase in ('starsoffseason6','starsoffseason7','starsoffseason8') -- if this is changed, match filter in game_list
;

-- game filter
drop table if exists game_list;
create temporary table game_list as
select game_id from (
select game_id,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY (winner_incoming_elo+loser_incoming_elo)/2) as game_elo -- do not edit this line
from game_history gh left join tag_set ts on gh.tag_set_id = ts.id
where ts.name_lowercase in ('starsoffseason6','starsoffseason7','starsoffseason8')
group by 1
) tbl where game_elo >= (select * from percentile_temp)
;

-- winrate query
select bowser_team_win_flag, count(distinct game_id) games from (
select game_id, case when bowser_on_team =1 and winner_username = username_lowercase then 1 else 0 end bowser_team_win_flag from(
select * from (
select game_id, winner_username, username_lowercase, max(case when name_lowercase ='bowser' then 1 else 0 end) bowser_on_team from(
select cgs.game_id, ru.username_lowercase, ru.id, ch.name_lowercase, ga.winner_username
from character_game_summary cgs 
left join rio_user ru on cgs.user_id = ru.id 
left join character ch on cgs.char_id = ch.char_id
left join (select ga.game_id, ga.away_player_id, ga.home_player_id, aru.username_lowercase, hru.username_lowercase, ga.away_score, ga.home_score,
                  case when ga.away_score > ga.home_score then aru.username_lowercase
                       when ga.home_score > ga.away_score then hru.username_lowercase
                       else null end winner_username
           from game ga
           left join rio_user aru on ga.away_player_id = aru.id
           left join rio_user hru on ga.home_player_id = hru.id
           --where ga.game_id = 34669344597
           ) ga on cgs.game_id = ga.game_id
where cgs.game_id in (select distinct game_id from game_list)
) a group by 1,2,3
) tbl where bowser_on_team =1 
) b 
) c group by 1
;




 -- bowser winrate with stadiums

 -- percentile
drop table if exists percentile_temp;
create temporary table percentile_temp as
select PERCENTILE_CONT(0.80) -- change this to select percentile
WITHIN GROUP(ORDER BY (winner_incoming_elo+loser_incoming_elo)/2) from game_history gh left join tag_set ts on gh.tag_set_id = ts.id
where ts.name_lowercase in ('starsoffseason6','starsoffseason7','starsoffseason8') -- if this is changed, match filter in game_list
;

-- game filter
drop table if exists game_list;
create temporary table game_list as
select game_id from (
select game_id,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY (winner_incoming_elo+loser_incoming_elo)/2) as game_elo -- do not edit this line
from game_history gh left join tag_set ts on gh.tag_set_id = ts.id
where ts.name_lowercase in ('starsoffseason6','starsoffseason7','starsoffseason8')
and gh.game_id in (select distinct game_id from game where stadium_id =5) -- change this to select stadium
group by 1
) tbl where game_elo >= (select * from percentile_temp)
;

-- winrate query
select bowser_team_win_flag, count(distinct game_id) games from (
select game_id, case when bowser_on_team =1 and winner_username = username_lowercase then 1 else 0 end bowser_team_win_flag from(
select * from (
select game_id, winner_username, username_lowercase, max(case when name_lowercase ='bowser' then 1 else 0 end) bowser_on_team from(
select cgs.game_id, ru.username_lowercase, ru.id, ch.name_lowercase, ga.winner_username
from character_game_summary cgs 
left join rio_user ru on cgs.user_id = ru.id 
left join character ch on cgs.char_id = ch.char_id
left join (select ga.game_id, ga.away_player_id, ga.home_player_id, aru.username_lowercase, hru.username_lowercase, ga.away_score, ga.home_score,
                  case when ga.away_score > ga.home_score then aru.username_lowercase
                       when ga.home_score > ga.away_score then hru.username_lowercase
                       else null end winner_username
           from game ga
           left join rio_user aru on ga.away_player_id = aru.id
           left join rio_user hru on ga.home_player_id = hru.id
           --where ga.game_id = 34669344597
           ) ga on cgs.game_id = ga.game_id
where cgs.game_id in (select distinct game_id from game_list)
) a group by 1,2,3
) tbl where bowser_on_team =1 
) b 
) c group by 1
;


-- case when ga.stadium_id='0' then 'Mario Stadium'
-- 	   when ga.stadium_id='1' then 'Bowsers Castle'
--      when ga.stadium_id='2' then 'Warios Palace'
--      when ga.stadium_id='3' then 'Yoshis Island'
--  	   when ga.stadium_id='4' then 'Peachs Garden'
-- 	   when ga.stadium_id='5' then 'DKs Jungle'
--      when ga.stadium_id='6' then 'Toy Field'
--      else 'unknown stadium name'
--      end stadium_name,