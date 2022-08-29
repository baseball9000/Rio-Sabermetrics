-- character combo winrates --------------- thanners#8647 on discord, 8/28/22
-- ('bro(h)', 'bro(f)', 'bro(b)')

-- edit lines 39 and 80 to run 2 character combos

drop table if exists temp_c1;
create temp table temp_c1 as 

with x as (select 'off' as competition) 

                select 
                 cgs.game_id,
                 awayru.username_lowercase away_user, 
                 homeru.username_lowercase home_user, 
                 ga.away_score, 
                 ga.home_score, 
                 ru.username_lowercase, 
                 ch.name_lowercase, 
                 team_id, 
                 roster_loc, concat(cgs.game_id,'-',team_id) chpk,
                 cgs.singles, 
                 cgs.doubles, 
                 cgs.triples, 
                 cgs.homeruns, 
                 cgs.walks_bb, 
                 cgs.walks_hit, 
                 cgs.strikeouts, 
                 cgs.at_bats
                from character_game_summary cgs 
                left join game ga on cgs.game_id = ga.game_id
                left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                left join character ch on ch.char_id = cgs.char_id
                left join rio_user ru on ru.id = cgs.user_id
                left join rio_user awayru on awayru.id = ga.away_player_id
                left join rio_user homeru on homeru.id = ga.home_player_id
                
                where ch.name_lowercase in ('bowser')
                and lower(ranked::text) ='true'
                    and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                end)
                order by cgs.game_id, cgs.team_id, cgs.roster_loc asc
                ;


drop table if exists temp_c2;
create temp table temp_c2 as

with x as (select 'off' as competition)        

                select 
                 cgs.game_id, 
                 ru.username_lowercase, 
                 awayru.username_lowercase away_user, 
                 homeru.username_lowercase home_user, 
                 ch.name_lowercase, 
                 team_id, 
                 roster_loc, 
                 concat(cgs.game_id,'-',team_id) chpk,
                 cgs.singles, 
                 cgs.doubles, 
                 cgs.triples, 
                 cgs.homeruns, 
                 cgs.walks_bb, 
                 cgs.walks_hit, 
                 cgs.strikeouts, 
                 cgs.at_bats
                from character_game_summary cgs 
                left join game ga on cgs.game_id = ga.game_id
                left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                left join character ch on ch.char_id = cgs.char_id
                left join rio_user ru on ru.id = cgs.user_id
                left join rio_user awayru on awayru.id = ga.away_player_id
                left join rio_user homeru on homeru.id = ga.home_player_id
                
                where ch.name_lowercase in ('shy guy (b)')
                and lower(ranked::text) ='true'
                    and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                end)
                order by cgs.game_id, cgs.team_id, cgs.roster_loc asc;                


drop table if exists temp_pb;
create temp table temp_pb as

                select p.*,
                b.username_lowercase c2_username_lowercase, 
                b.name_lowercase c2_name_lowercase, 
                b.team_id c2_team_id, 
                b.roster_loc c2_roster_loc,
                b.chpk c2_chpk,
                b.singles c2_singles, 
                b.doubles c2_doubles, 
                b.triples c2_triples, 
                b.homeruns c2_homeruns, 
                b.walks_bb c2_walks_bb, 
                b.walks_hit c2_walks_hit, 
                b.strikeouts c2_strikeouts, 
                b.at_bats bro_at_bats
                from temp_c1 p join temp_c2 b on p.chpk = b.chpk
                ;

                --select * from temp_pb;

select sum(case when winner_of_game = username_lowercase then 1 else 0 end),
count (*) from(
                select case when away_score > home_score then away_user
                            when home_score > away_score then home_user
                            end winner_of_game,
                            username_lowercase       
                from temp_pb
)a;












-----------------------------------------------------------------------------------------------------











-- character combo winrates
-- 3 characters at once -- edit lines 179, 219, and 258 to run 3 character combos
-- ('bro(h)', 'bro(f)', 'bro(b)')

drop table if exists temp_1;
create temp table temp_1 as 

with x as (select 'off' as competition) 

                select cgs.game_id, 
                awayru.username_lowercase away_user, 
                homeru.username_lowercase home_user, 
                ga.away_score, 
                ga.home_score, 
                ru.username_lowercase, 
                ch.name_lowercase, 
                team_id, 
                roster_loc, 
                concat(cgs.game_id,'-',team_id) chpk,
                cgs.singles, 
                cgs.doubles, 
                cgs.triples, 
                cgs.homeruns, 
                cgs.walks_bb, 
                cgs.walks_hit, 
                cgs.strikeouts, 
                cgs.at_bats
                from character_game_summary cgs 
                left join game ga on cgs.game_id = ga.game_id
                left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                left join character ch on ch.char_id = cgs.char_id
                left join rio_user ru on ru.id = cgs.user_id
                left join rio_user awayru on awayru.id = ga.away_player_id
                left join rio_user homeru on homeru.id = ga.home_player_id
                
                where ch.name_lowercase in ('petey')
                and lower(ranked::text) ='true'
                    and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                end)
                order by cgs.game_id, cgs.team_id, cgs.roster_loc asc
                ;


drop table if exists temp_2;
create temp table temp_2 as

with x as (select 'off' as competition)        

                select cgs.game_id, 
                ru.username_lowercase, 
                awayru.username_lowercase away_user, 
                homeru.username_lowercase home_user, 
                ch.name_lowercase, 
                team_id, 
                roster_loc, 
                concat(cgs.game_id,'-',team_id) chpk,
                cgs.singles,
                cgs.doubles, 
                cgs.triples, 
                cgs.homeruns, 
                cgs.walks_bb, 
                cgs.walks_hit, 
                cgs.strikeouts, 
                cgs.at_bats
                from character_game_summary cgs 
                left join game ga on cgs.game_id = ga.game_id
                left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                left join character ch on ch.char_id = cgs.char_id
                left join rio_user ru on ru.id = cgs.user_id
                left join rio_user awayru on awayru.id = ga.away_player_id
                left join rio_user homeru on homeru.id = ga.home_player_id
                
                where ch.name_lowercase in ('boo')
                and lower(ranked::text) ='true'
                    and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                end)
                order by cgs.game_id, cgs.team_id, cgs.roster_loc asc;                


drop table if exists temp_3;
create temp table temp_3 as

with x as (select 'off' as competition)        

                select cgs.game_id, 
                ru.username_lowercase, 
                awayru.username_lowercase away_user, 
                homeru.username_lowercase home_user, 
                ch.name_lowercase, 
                team_id, 
                roster_loc, 
                concat(cgs.game_id,'-',team_id) chpk,
                cgs.singles, 
                cgs.doubles, 
                cgs.triples, 
                cgs.homeruns, 
                cgs.walks_bb, 
                cgs.walks_hit, 
                cgs.strikeouts, 
                cgs.at_bats
                from character_game_summary cgs 
                left join game ga on cgs.game_id = ga.game_id
                left join (select gt.game_id, string_agg(ta.name_lowercase::text, ', ') as tag_names, string_agg(gt.tag_id::text, ', ') as tag_ids
                    from game_tag gt left join tag ta on  gt.tag_id = ta.id
                    group by 1) gt on ga.game_id = gt.game_id
                left join character ch on ch.char_id = cgs.char_id
                left join rio_user ru on ru.id = cgs.user_id
                left join rio_user awayru on awayru.id = ga.away_player_id
                left join rio_user homeru on homeru.id = ga.home_player_id
                
                where ch.name_lowercase in ('yoshi')
                and lower(ranked::text) ='true'
                    and (case when (select * from x)='off' then (lower(tag_names) like '%normal%' and lower(tag_names) not like '%superstar%')
                when (select * from x)='on' then (lower(tag_names) like '%superstar%')
                end)
                order by cgs.game_id, cgs.team_id, cgs.roster_loc asc;   

drop table if exists temp_pb;
create temp table temp_pb as

                select p.*,
                b.username_lowercase bro_username_lowercase, b.name_lowercase bro_name_lowercase, b.team_id bro_team_id, b.roster_loc bro_roster_loc, b.chpk bro_chpk,
                b.singles bro_singles, b.doubles bro_doubles, b.triples bro_triples, b.homeruns bro_homeruns, b.walks_bb bro_walks_bb, b.walks_hit bro_walks_hit, b.strikeouts bro_strikeouts, b.at_bats bro_at_bats,
                c.username_lowercase next_username_lowercase, c.name_lowercase next_name_lowercase, c.team_id next_team_id, c.roster_loc next_roster_loc, c.chpk next_chpk,
                c.singles next_singles, c.doubles next_doubles, c.triples next_triples, c.homeruns next_homeruns, c.walks_bb next_walks_bb, c.walks_hit next_walks_hit, c.strikeouts next_strikeouts, c.at_bats next_at_bats
                from temp_1 p join temp_2 b on p.chpk = b.chpk
                join temp_3 c on p.chpk = c.chpk and b.chpk = c.chpk
                ;

select sum(case when winner_of_game = username_lowercase then 1 else 0 end),
count (*) from(
                select case when away_score > home_score then away_user
                            when home_score > away_score then home_user
                            end winner_of_game,
                            username_lowercase       
                from temp_pb
)a;
