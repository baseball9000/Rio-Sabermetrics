-- frame data remake
-- 8/19/2024

select ch.name_lowercase, cs.frame_of_swing_upon_contact, contact_absolute, charge_power_up, charge_power_down, chem_links_ob,
case when half_inning::text ='0' then aru.username_lowercase
     when half_inning::text ='1' then hru.username_lowercase
     end batter_username,
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

case when cs.secondary_result::text in ('0','1','2','14','16') then 'out'
    when cs.secondary_result::text in ('3') then 'foul'
    when cs.secondary_result::text in ('7') then 'single'
    when cs.secondary_result::text in ('8') then 'double'
    when cs.secondary_result::text in ('9') then 'triple'
    when cs.secondary_result::text in ('10') then 'homerun'
    when cs.secondary_result::text in ('11', '12') then 'induced error'
    when cs.secondary_result::text in ('13') then 'bunt'
    when cs.secondary_result::text in ('15') then 'double play'
    end result,
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
case when ga.stadium_id='0' then 'Mario Stadium'
	 when ga.stadium_id='1' then 'Bowsers Castle'
     when ga.stadium_id='2' then 'Warios Palace'
     when ga.stadium_id='3' then 'Yoshis Island'
 	 when ga.stadium_id='4' then 'Peachs Garden'
	 when ga.stadium_id='5' then 'DKs Jungle'
     when ga.stadium_id='6' then 'Toy Field'
     else 'unknown stadium name'
     end stadium_name,
case when lower(cgs.batting_hand::text) ='false' then 'righty' else 'lefty' end as batting_hand
from game ga
left join rio_user aru on ga.away_player_id = aru.id
left join rio_user hru on ga.home_player_id = hru.id
left join game_history gh on ga.game_id = gh.game_id
left join tag_set ts on gh.tag_set_id = ts.id
left join event ev on ga.game_id = ev.game_id
left join pitch_summary ps on ev.pitch_summary_id = ps.id
left join contact_summary cs on ps.contact_summary_id = cs.id
left join character_game_summary cgs on ev.batter_id = cgs.id
left join character ch on cgs.char_id = ch.char_id
where --ga.game_id = 34669344597 and cs.id is not null  limit 20
ts.name_lowercase in (
'starsoffseason6',
'starsoffseason7',
'starsoffseason8',
's9superstarsoff'
)
and cs.id is not null
;
