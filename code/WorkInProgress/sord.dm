// big bad file of bad things i may or may not use

//panic button
/obj/item/device/panicbutton
	name = "panic button"
	desc = "A big red button that alerts the station Security team that there's a crisis at your location. On the bottom someone has scribbled 'oh shit button', cute."
	icon_state = "panic_button"
	w_class = W_CLASS_TINY
	var/net_id = null
	var/alert_group = list(MGD_SECURITY, MGA_CRISIS)

	New()
		. = ..()
		src.net_id = generate_net_id(src)
		MAKE_SENDER_RADIO_PACKET_COMPONENT(src.net_id, "pda", FREQ_PDA)

	attack_self(mob/user)
		..()
		if(!ON_COOLDOWN(src, "panic button", 15 SECONDS))
			if(isliving(user))
				playsound(src, 'sound/items/security_alert.ogg', 30)
				usr.visible_message(SPAN_ALERT("[usr] presses the red button on [src]."),
				SPAN_NOTICE("You press the button on [src]."),
				SPAN_ALERT("You see [usr] press a button on [src]."))
				triggerpanicbutton()
		else
			boutput(user, SPAN_NOTICE("The [src] buzzes faintly. It must be cooling down."))

	proc/triggerpanicbutton(user)
		var/datum/signal/signal = get_free_signal()
		var/area/an_area = get_area(src)
		signal.source = src
		signal.data["command"] = "text_message"
		signal.data["sender_name"] = "PANIC-BUTTON"
		signal.data["group"] = src.alert_group
		signal.data["sender"] = "00000000"
		signal.data["address_1"] = "00000000"
		signal.data["message"] = "***CRISIS ALERT*** Location: [an_area ? an_area.name : "nowhere"]!"
		signal.data["is_alert"] = TRUE

		SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal, null, FREQ_PDA)

/obj/item/device/panicbutton/medicalalert //really just adding this for the hop version but hey maybe medical wants to hand out medical life alert buttons for the funny
	name = "medical alert button"
	desc = "A big red button that alerts the station Medical team that there's a crisis at your location."
	alert_group = list(MGD_MEDBAY, MGA_CRISIS)

/obj/item/device/panicbutton/medicalalert/hop
	name = "life alert button"
	desc = "For when you've got a REAL BIG problem and want EVERYONE to know about it."
	alert_group = list(MGD_PARTY, MGD_MEDBAY, MGD_SECURITY, MGD_COMMAND, MGA_CRISIS) // lol. lmao, even

/obj/item/storage/box/panic_buttons
	name = "box of panic buttons"
	desc = "A box filled with panic buttons. For when you have a real big problem and need a whole lot of people to freak out about it. Note: DEFINITELY keep out of reach of the clown and/or assistants."
	spawn_contents = list(/obj/item/device/panicbutton = 7)

/obj/item/storage/box/panic_buttons/medicalalert
	name = "box of medical alert buttons"
	desc = "A box filled with medical alert buttons."
	spawn_contents = list(/obj/item/device/panicbutton/medicalalert = 7)

//dazzler. moved to own file. probably wont do anything with this
/obj/item/gun/energy/dazzler
	name = "dazzler"
	icon_state = "taser" // wtb 1 sprite
	item_state = "taser"
	force = 1
	cell_type = /obj/item/ammo/power_cell/med_power
	desc = "The Five Points Armory Dazzler Prototype, an experimental weapon that produces a cohesive electrical charge designed to disorient and slowdown a target. It can even shoot through windows!"
	muzzle_flash = "muzzle_flash_bluezap"
	uses_charge_overlay = TRUE
	charge_icon_state = "taser"

	New()
		set_current_projectile(new/datum/projectile/energy_bolt/dazzler)
		projectiles = list(current_projectile)
		..()


/datum/projectile/energy_bolt/dazzler
	name = "energy bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "signifer2_brute"
	stun = 4
	cost = 20
	max_range = 12
	window_pass = 1 // maybe keep
	dissipation_rate = 0 // weak enough as is
	sname = "dazzle"
	shot_sound = 'sound/weapons/Taser.ogg'
	shot_sound_extrarange = 5
	shot_number = 1
	damage_type = D_ENERGY
	color_red = 0
	color_green = 0
	color_blue = 1
	disruption = 8

/obj/item/swords/sord
	name = "gross sord"
	desc = "oh no"
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "longsword"
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	color = "#4a996c"
	hit_type = DAMAGE_CUT
	flags = TABLEPASS | NOSHIELD | USEDELAY
	force = 10
	throwforce = 5
	throw_speed = 1
	throw_range = 5
	is_syndicate = TRUE
	contraband = 10 // absolutely illegal
	w_class = W_CLASS_NORMAL
	hitsound = 'sound/voice/farts/fart7.ogg'
	tool_flags = TOOL_CUTTING
	attack_verbs = "slashes"

	New()
		..()
		src.setItemSpecial(/datum/item_special/rangestab)

