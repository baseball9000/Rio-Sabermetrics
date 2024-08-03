-- WITH
-- table1 as 
-- (select 0 as bucket_0,
-- 0 as bucket_1,
-- 15 as bucket_2,
-- 25 as bucket_3,
-- 100 as bucket_4,
-- 16 as randomsum)

-- select
-- case 
-- when randomsum::int <= bucket_0_upper_randomsum and bucket_0_upper_randomsum <> 0 then '0'
-- when randomsum::int between bucket_0_upper_randomsum and bucket_1_upper_randomsum and bucket_1_upper_randomsum <> 0 then '1'
-- when randomsum::int between bucket_1_upper_randomsum and bucket_2_upper_randomsum and bucket_2_upper_randomsum <> 0 then '2'
-- when randomsum::int between bucket_2_upper_randomsum and bucket_3_upper_randomsum and bucket_3_upper_randomsum <> 0 then '3'
-- when randomsum::int between bucket_3_upper_randomsum and bucket_4_upper_randomsum and bucket_4_upper_randomsum <> 0 then '4'
-- end bucket
-- from table1






select 
date_time_start2,
away_username,
home_username,
stadium_name,
game_id,
gametype,
event_num,
home_score,
away_score,
inning,
half_inning,
pitcher,
batter,
type_of_swing_name,
type_of_contact_name,
stick_input,
frame_of_swing_upon_contact,
contact_quality,

case 
when randomsum::int <= bucket_0_upper_randomsum and bucket_0_upper_randomsum <> 0 then 'low'
when randomsum::int between bucket_0_upper_randomsum and bucket_1_upper_randomsum and bucket_1_upper_randomsum <> 0 then 'mid-low'
when randomsum::int between bucket_1_upper_randomsum and bucket_2_upper_randomsum and bucket_2_upper_randomsum <> 0 then 'mid'
when randomsum::int between bucket_2_upper_randomsum and bucket_3_upper_randomsum and bucket_3_upper_randomsum <> 0 then 'mid-high'
when randomsum::int between bucket_3_upper_randomsum and bucket_4_upper_randomsum and bucket_4_upper_randomsum <> 0 then 'high'
when type_of_swing_name = 'star' then 'star hit trajectory'
end traj_bucket,

bucket_0_chance_percentage,
bucket_1_chance_percentage,
bucket_2_chance_percentage,
bucket_3_chance_percentage,
bucket_4_chance_percentage,

case when coalesce(event_name_final, result_of_ab_named) ='none'
and type_of_swing_name ='none'
and in_strikezone is FALSE
then 'ball'
when coalesce(event_name_final, result_of_ab_named) ='none'
and in_strikezone is TRUE
then 'strike'
when coalesce(event_name_final, result_of_ab_named) ='none'
and type_of_swing_name <> 'none'
and type_of_contact_name is NULL
then 'strike'
else coalesce(event_name_final, result_of_ab_named)
end as event_name_actual_final, 

case when half_inning::text ='0' then away_username
     when half_inning::text ='1' then home_username
     end batter_username
from(
select
to_char(to_timestamp(ga.date_time_start), 'YYYY-MM-DD HH:MI:SS') as date_time_start,
to_timestamp(ga.date_time_start)-interval '4 hours' as date_time_start2,
aru.username_lowercase away_username,
hru.username_lowercase home_username,
case when ga.stadium_id='0' then 'Mario Stadium'
	 when ga.stadium_id='1' then 'Bowsers Castle'
     when ga.stadium_id='2' then 'Warios Palace'
     when ga.stadium_id='3' then 'Yoshis Island'
 	 when ga.stadium_id='4' then 'Peachs Garden'
	 when ga.stadium_id='5' then 'DKs Jungle'
     when ga.stadium_id='6' then 'Toy Field'
     else 'unknown stadium name'
     end stadium_name,
ga.innings_selected,
ga.innings_played,
case when ga.quitter ='0' then 'away quit'
     when ga.quitter ='1' then 'home quit'
     when ga.quitter ='255' then 'neither quit'
     else null end as quitter,
ga.version,
ga.game_id,
ts.name_lowercase as gametype,
gh.winner_incoming_elo,
gh.winner_result_elo,
ev.event_num,
ev.home_score,
ev.away_score,
ev.chem_links_ob,
ev.inning,
ev.half_inning,
case
    when ev.result_of_ab = '0' then 'none'
    when ev.result_of_ab = '1' then 'strikeout'
    when ev.result_of_ab = '2' then 'walk (bb)'
    when ev.result_of_ab = '3' then 'walk (hbp)'
    when ev.result_of_ab = '4' then 'out'
    when ev.result_of_ab = '5' then 'caught'
    when ev.result_of_ab = '6' then 'caught line drive'
    when ev.result_of_ab = '7' then 'single'
    when ev.result_of_ab = '8' then 'double'
    when ev.result_of_ab = '9' then 'triple'
    when ev.result_of_ab = '10' then 'HR'
    when ev.result_of_ab = '11' then 'rboe'
    when ev.result_of_ab = '12' then 'chem error'
    when ev.result_of_ab = '13' then 'bunt'
    when ev.result_of_ab = '14' then 'sacfly'
    when ev.result_of_ab = '15' then 'gidp'
    when ev.result_of_ab = '16' then 'foul catch'
        end result_of_ab_named,
pcgs.name_lowercase pitcher,
case when lower(pcgs.fielding_hand::text) ='false' then 'lefty' else 'righty' end as fielding_hand,
bcgs.name_lowercase batter,
case when lower(bcgs.batting_hand::text) ='false' then 'righty' else 'lefty' end as batting_hand,
bcgs.hit_trajectory_mhl,
case when ps.pitch_type::text ='0' then 'curve'
     when ps.pitch_type::text ='1' then 'charge'
     when ps.pitch_type::text ='2' then 'changeup'
     end as pitch_type,
case when ps.charge_pitch_type::text ='0' then 'N/A'
     when ps.charge_pitch_type::text ='2' then 'slider'
     when ps.charge_pitch_type::text ='3' then 'perfect'
     end as charge_pitch_type,
case when ps.pitch_type::text = '0' then 'curve'
     when ps.pitch_type::text = '1' and ps.charge_pitch_type::text ='2' then 'non-perfect charge'
     when ps.pitch_type::text = '1' and ps.charge_pitch_type::text ='3' then 'perfect charge'
     when ps.pitch_type::text = '2' then 'changeup'
     end total_pitch_type,
case when ps.star_pitch::text ='0' then 'no'
     when ps.star_pitch::text ='1' then 'yes'
     end as star_pitch,
ps.pitch_speed,
ps.in_strikezone,
case when ps.type_of_swing::text ='0' then 'none'
     when ps.type_of_swing::text ='1' then 'slap'
     when ps.type_of_swing::text ='2' then 'charge'
     when ps.type_of_swing::text ='3' then 'star'
     when ps.type_of_swing::text ='4' then 'bunt'
     else ps.type_of_swing::text
     end type_of_swing_name,
case when cs.type_of_contact::text ='0' then 'sour-left'
     when cs.type_of_contact::text ='1' then 'nice-left'
     when cs.type_of_contact::text ='2' then 'perfect'
     when cs.type_of_contact::text ='3' then 'nice-right'
     when cs.type_of_contact::text ='4' then 'sour-right'
     else cs.type_of_contact::text
     end type_of_contact_name,
cs.charge_power_up,
cs.charge_power_down,
cs.star_swing_five_star,
case when cs.input_direction_stick::text ='0' then 'none'  
  	 when cs.input_direction_stick::text ='1' then 'left'
     when cs.input_direction_stick::text ='2' then 'right' 
     when cs.input_direction_stick::text ='4' then 'down' 
     when cs.input_direction_stick::text ='5' then 'down and left' 
     when cs.input_direction_stick::text ='6' then 'down and right' 
     when cs.input_direction_stick::text ='8' then 'up' 
     when cs.input_direction_stick::text ='9' then 'up and left' 
     when cs.input_direction_stick::text ='10' then 'up and right'
  	 when cs.input_direction_stick::text ='14' then 'up and down and right lol?'
   	 else cs.input_direction_stick::text
  	 end stick_input,
case when cs.input_direction::text ='0' then 'none'  
  	 when cs.input_direction::text ='1' then 'towards batter'
     when cs.input_direction::text ='2' then 'away from batter' 
     end stick_input_relative,
cs.frame_of_swing_upon_contact,
cs.contact_absolute,
cs.contact_quality,
cs.rng1,
cs.rng2,
cs.rng3,
(cs.ball_y_velocity/(sqrt((ball_x_velocity*ball_x_velocity)+(ball_z_velocity*ball_z_velocity)))),
atan((cs.ball_y_velocity/(sqrt((ball_x_velocity*ball_x_velocity)+(ball_z_velocity*ball_z_velocity))))::float)*(180/3.1415926535) as ball_angle_degrees,
cs.ball_vert_angle,
CASE 
when bcgs.hit_trajectory_mhl::text='1' 
and cs.type_of_contact::text ='2'
and ps.type_of_swing::text ='1'
THEN
abs((((rng1::int - (rng2::int % 256)) + (rng2::int / 105) + rng3::int) % 105))
ELSE
abs((((rng1::int - (rng2::int % 256)) + (rng2::int / 100) + rng3::int) % 100))
end as randomsum1,
CASE 
when bcgs.hit_trajectory_mhl::text='1' 
and cs.type_of_contact::text ='2'
and ps.type_of_swing::text ='1'
THEN

((((((cs.rng1::int)-(right(((cs.rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/105)+(rng3::int))-(floor(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/105)+(rng3::int))::int)/105)*105))::int >> 31)#((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/105)+(rng3::int))-(floor(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/105)+(rng3::int))::int)/105)*105))::int)-(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/105)+(rng3::int))-(floor(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/105)+(rng3::int))::int)/105)*105)
)::int >> 31)

ELSE

((((((cs.rng1::int)-(right(((cs.rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/100)+(rng3::int))-(floor(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/100)+(rng3::int))::int)/100)*100))::int >> 31)#((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/100)+(rng3::int))-(floor(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/100)+(rng3::int))::int)/100)*100))::int)-(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/100)+(rng3::int))-(floor(((((rng1::int)-(right(((rng2::int)::bit(32)::text),8)::bit(8) & B'11111111')::int)
+floor((rng2::int)/100)+(rng3::int))::int)/100)*100)
)::int >> 31) END as randomsum,

cs.ball_max_height,
cs.ball_hang_time,
COALESCE(case
    when cs.secondary_result::text in ('0','1','2','14','16') then 'out'
    when cs.secondary_result::text in ('3') then 'foul'
    when cs.secondary_result::text in ('7') then 'single'
    when cs.secondary_result::text in ('8') then 'double'
    when cs.secondary_result::text in ('9') then 'triple'
    when cs.secondary_result::text in ('10') then 'homerun'
    when cs.secondary_result::text in ('11', '12') then 'induced error'
    when cs.secondary_result::text in ('13') then 'bunt'
    when cs.secondary_result::text in ('15') then 'double play'
    end, case
    when ev.result_of_ab = '0' then 'none'
    when ev.result_of_ab = '1' then 'strikeout'
    when ev.result_of_ab = '2' then 'walk (bb)'
    when ev.result_of_ab = '3' then 'walk (hbp)'
    when ev.result_of_ab = '4' then 'out'
    when ev.result_of_ab = '5' then 'caught'
    when ev.result_of_ab = '6' then 'caught line drive'
    when ev.result_of_ab = '7' then 'single'
    when ev.result_of_ab = '8' then 'double'
    when ev.result_of_ab = '9' then 'triple'
    when ev.result_of_ab = '10' then 'HR'
    when ev.result_of_ab = '11' then 'rboe'
    when ev.result_of_ab = '12' then 'chem error'
    when ev.result_of_ab = '13' then 'bunt'
    when ev.result_of_ab = '14' then 'sacfly'
    when ev.result_of_ab = '15' then 'gidp'
    when ev.result_of_ab = '16' then 'foul catch'
        end) event_name_final,
case when cs.primary_result::text ='0' then 'out'  
  	 when cs.primary_result::text ='1' then 'foul'
     when cs.primary_result::text ='2' then 'fair'
     when cs.primary_result::text ='3' then 'fielded'
     when cs.primary_result::text ='4' then 'unknown' 
     else cs.primary_result::text
     end primary_result_of_contact_name,
case
    when cs.secondary_result::text in ('0','1','2','14','16') then 'out'
    when cs.secondary_result::text in ('3') then 'foul'
    when cs.secondary_result::text in ('7') then 'single'
    when cs.secondary_result::text in ('8') then 'double'
    when cs.secondary_result::text in ('9') then 'triple'
    when cs.secondary_result::text in ('10') then 'homerun'
    when cs.secondary_result::text in ('11', '12') then 'induced error'
    when cs.secondary_result::text in ('13') then 'bunt'
    when cs.secondary_result::text in ('15') then 'double play'
    end secondary_result_of_contact_named,
fs.name_lowercase fielder_name,
case when fs.position::text ='0' then 'p'
     when fs.position::text ='1' then 'c'
     when fs.position::text ='2' then '1b'
     when fs.position::text ='3' then '2b'
     when fs.position::text ='4' then '3b'
     when fs.position::text ='5' then 'ss'
     when fs.position::text ='6' then 'lf'
     when fs.position::text ='7' then 'cf'
     when fs.position::text ='8' then 'rf'
     else fs.position::text 
     end fielder_position,
case when fs.action::text ='0' then 'none'
     when fs.action::text ='2' then 'sliding'
     when fs.action::text ='3' then 'walljump'
     end fielder_action,
fs.jump,
case when fs.bobble::text ='0' then 'none'
     when fs.bobble::text ='1' then 'slide/stun lock' -- unsure if this one matters, no occurrence in data
     when fs.bobble::text ='2' then 'fumble'
     when fs.bobble::text ='3' then 'bobble'
     when fs.bobble::text ='4' then 'fireball'
     when fs.bobble::text ='16' then 'garlic'
     else fs.bobble::text
     end fielder_bobble,
case when fs.manual_select::text ='0' then 'no selected character'
     when fs.manual_select::text ='1' then 'selected other character'
     when fs.manual_select::text ='2' then 'selected this character'
     end fielder_manual_select_name,

vt.bucket_0_upper_randomsum,
vt.bucket_1_upper_randomsum,
vt.bucket_2_upper_randomsum,
vt.bucket_3_upper_randomsum,
vt.bucket_4_upper_randomsum,
vt.bucket_0_chance_percentage,
vt.bucket_1_chance_percentage,
vt.bucket_2_chance_percentage,
vt.bucket_3_chance_percentage,
vt.bucket_4_chance_percentage

from game ga
left join rio_user aru on ga.away_player_id = aru.id
left join rio_user hru on ga.home_player_id = hru.id
left join game_history gh on ga.game_id = gh.game_id
left join tag_set ts on gh.tag_set_id = ts.id
left join event ev on ga.game_id = ev.game_id
left join (select a.id, a.fielding_hand, b.name_lowercase from character_game_summary a left join character b on a.char_id = b.char_id) pcgs on ev.pitcher_id = pcgs.id
left join (select a.id, a.batting_hand, b.name_lowercase, b.hit_trajectory_mhl from character_game_summary a left join character b on a.char_id = b.char_id) bcgs on ev.batter_id = bcgs.id
left join (select a.id, b.name_lowercase from character_game_summary a left join character b on a.char_id = b.char_id) ccgs on ev.catcher_id = ccgs.id
left join (select c.name_lowercase, a.id, a.initial_base, a.result_base, a.out_type, a.out_location, a.steal
           from runner a left join character_game_summary b on a.runner_character_game_summary_id = b.id left join character c on b.char_id = c.char_id)
           ru1 on ev.runner_on_1 = ru1.id
left join (select c.name_lowercase, a.id, a.initial_base, a.result_base, a.out_type, a.out_location, a.steal
           from runner a left join character_game_summary b on a.runner_character_game_summary_id = b.id left join character c on b.char_id = c.char_id)
           ru2 on ev.runner_on_2 = ru2.id
left join (select c.name_lowercase, a.id, a.initial_base, a.result_base, a.out_type, a.out_location, a.steal
           from runner a left join character_game_summary b on a.runner_character_game_summary_id = b.id left join character c on b.char_id = c.char_id)
           ru3 on ev.runner_on_3 = ru3.id
inner join (select ga.game_id, ga.away_player_id, ch.name_lowercase away_captain from game ga
            inner join rio_user ru on ga.away_player_id = ru.id
            inner join character_game_summary cg on ga.game_id = cg.game_id
                                   and ru.id = cg.user_id
            left join character ch on ch.char_id = cg.char_id
            where cg.captain IS TRUE) acap on acap.away_player_id = aru.id 
                                           and acap.game_id = ev.game_id
inner join (select ga.game_id, ga.home_player_id, ch.name_lowercase home_captain from game ga
            inner join rio_user ru on ga.home_player_id = ru.id
            inner join character_game_summary cg on ga.game_id = cg.game_id
                                   and ru.id = cg.user_id
            left join character ch on ch.char_id = cg.char_id
            where cg.captain IS TRUE) hcap on hcap.home_player_id = hru.id
                                           and hcap.game_id = ev.game_id
left join pitch_summary ps on ev.pitch_summary_id = ps.id
left join contact_summary cs on ps.contact_summary_id = cs.id
left join (select a.*, c.name_lowercase from fielding_summary a left join character_game_summary b
           on a.fielder_character_game_summary_id = b.id left join character c
           on b.char_id = c.char_id) fs on cs.fielding_summary_id = fs.id
left join vertical_trajectories vt on 
            case when bcgs.hit_trajectory_mhl =0 then 'mid'
                 when bcgs.hit_trajectory_mhl=1 then 'high'
                 when bcgs.hit_trajectory_mhl=2 then 'low' end = vt.character_trajectory
            and 
            case when cs.type_of_contact::text ='0' then 'sour-left'
                 when cs.type_of_contact::text ='1' then 'nice-left'
                 when cs.type_of_contact::text ='2' then 'perfect'
                 when cs.type_of_contact::text ='3' then 'nice-right'
                 when cs.type_of_contact::text ='4' then 'sour-right' end = vt.contact_type
            and
            case when ps.type_of_swing::text ='0' then 'none'
                 when ps.type_of_swing::text ='1' then 'slap'
                 when ps.type_of_swing::text ='2' then 'charge'
                 when ps.type_of_swing::text ='3' then 'star'
                 when ps.type_of_swing::text ='4' then 'bunt' end = vt.swing_type
            and
            case when cs.input_direction_stick::text ='0' then 'none'  
                 when cs.input_direction_stick::text ='1' then 'none'
                 when cs.input_direction_stick::text ='2' then 'none' 
                 when cs.input_direction_stick::text ='4' then 'down' 
                 when cs.input_direction_stick::text ='5' then 'down' 
                 when cs.input_direction_stick::text ='6' then 'down' 
                 when cs.input_direction_stick::text ='8' then 'up' 
                 when cs.input_direction_stick::text ='9' then 'up' 
                 when cs.input_direction_stick::text ='10' then 'up' end = vt.stick_input


 --where ga.game_id in('215907651987')

where to_char(to_timestamp(ga.date_time_start), 'YYYY-MM-DD HH:MI:SS')::date between current_date-30 and current_date
and ts.name_lowercase ='s9superstarsoff' -- change this to change gametype

-- and (ts.name_lowercase like ('s9%') or ts.name_lowercase like '%npss%' or ts.name_lowercase like '%netplaysuperstars%' or ts.name_lowercase like '%slice%' or ts.name_lowercase ='blastersummerclassic')
-- and (ts.name_lowercase not like 'practice')
)a 
order by date_time_start, game_id, event_num asc 
;


-- 'starsoffseason6',
-- 'starsoffseason7',
-- 'starsoffseason8',

