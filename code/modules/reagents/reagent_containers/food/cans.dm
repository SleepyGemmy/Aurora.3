//
// Cans
//

// Defines
#define LETHAL_FUEL_CAPACITY 21 // This many units of fuel will cause a harmful explosion.
#define FUSELENGTH_MAX       10 // This is the longest a fuse can be.
#define FUSELENGTH_MIN        3 // And the minimum that the builder can intentionally make.
#define FUSELENGTH_SHORT      5 // The upper boundary of the short fuse.
#define FUSELENGTH_LONG       6 // The lower boundary of the long fuse.
#define BOMBCASING_EMPTY      0 // No grenade casing.
#define BOMBCASING_LOOSE      1 // It is in a grenade casing but not secured.
#define BOMBCASING_SECURE     2 // It is in a grenade casing and secured - shrapnel count increased.

// Parent Item
/obj/item/reagent_containers/food/drinks/cans
	name = "can parent item"
	desc = DESC_PARENT
	icon = 'icons/obj/item/reagent_containers/food/drinks/cans.dmi'
	desc_info = "Activate it in your active hand to open it.<br>\
	- If it's carbonated and closed, you can shake it by activating it on harm intent.<br>\
	- If it's empty, you can crush it on your forehead by selecting your head on the targetting doll and clicking on yourself on harm intent.<br>\
	- You can also crush cans on other people's foreheads as well."
	drop_sound = 'sound/items/drop/soda.ogg'
	pickup_sound = 'sound/items/pickup/soda.ogg'
	flags = 0 // Item flag to check if you can pour stuff inside.
	amount_per_transfer_from_this = 5

	var/can_is_open = FALSE // If the can is opened. Used for the "open_overlay".
	var/sticker // Used to know which overlay sticker to put on the can.
	var/shadow_overlay = "33cl_shadow_overlay" // Used to know where the shadow overlay goes.
	var/open_overlay = "33cl_open_overlay" // Used to know where the open overlay goes.
	var/list/can_size_overrides = list("x" = 0, "y" = -3) // Position of the can's opening. Make sure to take away 16 from X and 23 from Y.

	// Bomb Code
	var/fuse_length = 0
	var/fuse_lit
	var/bombcasing
	var/shrapnelcount = 7

// Initialize()
/obj/item/reagent_containers/food/drinks/cans/Initialize()
	update_icon()
	..()

// attack()
/obj/item/reagent_containers/food/drinks/cans/attack(mob/living/M, mob/user, var/target_zone)
	if(iscarbon(M) && !reagents.total_volume && user.a_intent == I_HURT && target_zone == BP_HEAD)
		if(M == user)
			user.visible_message(
				SPAN_WARNING("\The [user] crushes \the [src] on [user.get_pronoun("his")] forehead!"),
				SPAN_WARNING("You crush \the [src] on your forehead.")
			)
		else
			user.visible_message(
				SPAN_WARNING("\The [user] crushes \the [src] on \the [M]'s forehead!"),
				SPAN_WARNING("You crush \the [src] on \the [M]'s forehead.")
			)
		M.apply_damage(2, DAMAGE_BRUTE, BP_HEAD)
		playsound(M, 'sound/items/soda_crush.ogg', rand(10, 50), TRUE)
		var/obj/item/trash/can/crushed_can = new /obj/item/trash/can(M.loc)
		crushed_can.name = "crushed [name]" // Set the crushed can's name based on its uncrushed counterpart's name.
		crushed_can.icon_state = "[sticker]-crushed" // Set the crushed can's icon state based on its uncrushed counterpart's sticker.
		qdel(src)
		user.put_in_hands(crushed_can)
		return TRUE
	. = ..()

// update_icon()
/obj/item/reagent_containers/food/drinks/cans/update_icon()
	cut_overlays()

	add_overlay(shadow_overlay)
	add_overlay(sticker)

	if(can_is_open)
		add_overlay(open_overlay)

	// Bomb Code
	if(fuse_length)
		var/image/fuseoverlay = image('icons/obj/fuses.dmi', icon_state = "fuse_short")
		switch(fuse_length)
			if(FUSELENGTH_LONG to INFINITY)
				fuseoverlay.icon_state = "fuse_long"
		if(fuse_lit)
			fuseoverlay.icon_state = "lit_fuse"
		fuseoverlay.pixel_x = can_size_overrides["x"]
		fuseoverlay.pixel_y = can_size_overrides["y"]
		add_overlay(fuseoverlay)

	if(bombcasing > BOMBCASING_EMPTY)
		var/image/casingoverlay = image('icons/obj/fuses.dmi', icon_state = "pipe_bomb")
		add_overlay(casingoverlay)

/obj/item/reagent_containers/food/drinks/cans/open(mob/user)
	can_is_open = TRUE
	name = "opened [name]"
	flags |= OPENCONTAINER
	user.visible_message(
		"\The <b>[user]</b> opens \the [src].",
		SPAN_NOTICE("You open \the [src] with an audible pop!"),
		SPAN_NOTICE("You can hear a pop.")
	)
	playsound(src,'sound/items/soda_open.ogg', rand(10, 50), TRUE)
	update_icon()

// attackby()
/obj/item/reagent_containers/food/drinks/cans/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/grenade/chem_grenade/large))
		var/obj/item/grenade/chem_grenade/grenade_casing = W
		if(!grenade_casing.detonator && !length(grenade_casing.beakers) && bombcasing < BOMBCASING_LOOSE)
			bombcasing = BOMBCASING_LOOSE
			desc = "A grenade casing with \a [name] slotted into it."
			if(fuse_length)
				desc += " It has some steel wool stuffed into the opening."
			user.visible_message(
				SPAN_NOTICE("[user] slots \the [grenade_casing] over \the [name]."),
				SPAN_NOTICE("You slot \the [grenade_casing] over \the [name].")
			)
			desc = "A grenade casing with \a [name] slotted into it."
			qdel(grenade_casing)
			update_icon()

	if(W.isscrewdriver() && bombcasing > BOMBCASING_EMPTY)
		if(bombcasing == BOMBCASING_LOOSE)
			bombcasing = BOMBCASING_SECURE
			shrapnelcount = 14
			user.visible_message(
				SPAN_NOTICE("[user] tightens the grenade casing around \the [name]."),
				SPAN_NOTICE("You tighten the grenade casing around \the [name].")
			)
		else if(bombcasing == BOMBCASING_SECURE)
			bombcasing = BOMBCASING_EMPTY
			shrapnelcount = initial(shrapnelcount)
			desc = initial(desc)
			if(fuse_length)
				desc += " It has some steel wool stuffed into the opening."
			user.visible_message(
				SPAN_NOTICE("[user] removes \the [name] from the grenade casing."),
				SPAN_NOTICE("You remove \the [name] from the grenade casing.")
			)
			new /obj/item/grenade/chem_grenade/large(get_turf(src))
		playsound(loc, W.usesound, 50, 1)
		update_icon()

	if(istype(W, /obj/item/steelwool))
		if(is_open_container())
			switch(fuse_length)
				if(-INFINITY to FUSELENGTH_MAX)
					user.visible_message(
						SPAN_NOTICE("\The [user] stuffs some steel wool into \the [name]."),
						SPAN_NOTICE("You feed steel wool into \the [name], ruining it in the process. It will last approximately 10 seconds.")
					)
					fuse_length = FUSELENGTH_MAX
					update_icon()
					desc += " It has some steel wool stuffed into the opening."
					if(W.isFlameSource())
						light_fuse(W, user, TRUE)
					qdel(W)
				if(FUSELENGTH_MAX)
					to_chat(user, SPAN_WARNING("You cannot make the fuse longer than 10 seconds!"))
		else
			to_chat(user, SPAN_WARNING("There is no opening on \the [name] for the steel wool!"))

	else if(W.iswirecutter() && fuse_length)
		switch(fuse_length)
			if(1 to FUSELENGTH_MIN) // you can't increase the fuse with wirecutters and you can't trim it down below 3, so just remove it outright.
				user.visible_message("<b>[user]</b> removes the steel wool from \the [name].", SPAN_NOTICE("You remove the steel wool fuse from \the [name]."))
				fuse_remove()
			if(4 to FUSELENGTH_MAX)
				var/fchoice = alert("Do you want to shorten or remove the fuse on \the [name]?", "Shorten or Remove", "Shorten", "Remove", "Cancel")
				switch(fchoice)
					if("Shorten")
						var/short = input("How many seconds do you want the fuse to be?", "[name] fuse") as null|num
						if(!use_check_and_message(user))
							if(short < fuse_length && short >= FUSELENGTH_MIN)
								to_chat(user, SPAN_NOTICE("You shorten the fuse to [short] seconds."))
								fuse_remove(fuse_length - short)
							else if(!short && !isnull(short))
								user.visible_message(
									"<b>[user]</b> removes the steel wool from \the [name]",
									SPAN_NOTICE("You remove the steel wool fuse from \the [name].")
									)
								fuse_remove()
							else if(short == fuse_length || isnull(short))
								to_chat(user, SPAN_NOTICE("You decide against modifying the fuse."))
							else if (short > fuse_length)
								to_chat(user, SPAN_WARNING("You cannot make the fuse longer than it already is!"))
							else if(short in list(1,2))
								to_chat(user, SPAN_WARNING("The fuse cannot be shorter than 3 seconds!"))
							else
								return
					if("Remove")
						if(!use_check_and_message(user))
							user.visible_message("<b>[user]</b> removes the steel wool from \the [name].", "You remove the steel wool fuse from \the [name].")
							fuse_remove()
					if("Cancel")
						return
				return

	else if(W.isFlameSource() && fuse_length)
		light_fuse(W, user)
	. = ..()

// light_fuse()
/obj/item/reagent_containers/food/drinks/cans/proc/light_fuse(obj/item/W, mob/user, var/premature=FALSE)
	if(can_light())
		fuse_lit = TRUE
		update_icon()
		set_light(2, 2, LIGHT_COLOR_LAVA)
		if(REAGENT_VOLUME(reagents, /singleton/reagent/fuel) >= LETHAL_FUEL_CAPACITY && user)
			msg_admin_attack("[user] ([user.ckey]) lit the fuse on an improvised [name] grenade. (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)",ckey=key_name(user))
			if(fuse_length >= FUSELENGTH_MIN && fuse_length <= FUSELENGTH_SHORT)
				user.visible_message(SPAN_DANGER("<b>[user]</b> accidentally takes \the [W] too close to \the [name]'s opening!"))
				detonate(TRUE) // it'd be a bit dull if the toy-levels of fuel had a chance to insta-pop, it's mostly just a way to keep the grenade balance in check
		if(fuse_length < FUSELENGTH_MIN)
			user.visible_message(
				SPAN_DANGER("<b>[user]</b> tries to light the fuse on \the [name] but it was too short!"),
				SPAN_DANGER("You try to light the fuse but it was too short!")
			)
			detonate(TRUE) // if you're somehow THAT determined and/or ignorant you managed to get the fuse below 3 seconds, so be it. reap what you sow.
		else
			if(premature)
				user.visible_message(
					SPAN_WARNING("<b>[user]</b> prematurely starts \the [name]'s fuse!"),
					SPAN_WARNING("You prematurely start \the [name]'s fuse!")
				)
			else
				user.visible_message(
					SPAN_WARNING("<b>[user]</b> lights the steel wool on \the [name] with \the [W]!"),
					SPAN_WARNING("You light the steel wool on \the [name] with the [W]!")
				)
			playsound(get_turf(src), 'sound/items/flare.ogg', 50)
			detonate(FALSE)

// detonate()
/obj/item/reagent_containers/food/drinks/cans/proc/detonate(var/instant)
	var/fuel = REAGENT_VOLUME(reagents, /singleton/reagent/fuel)
	if(instant)
		fuse_length = 0
	else if(prob(fuse_length * 6)) // The longer the fuse, the higher chance it will fizzle out (18% chance minimum).
		var/fizzle = rand(1, fuse_length - 1)
		sleep(fizzle * 1 SECOND)

		fuse_length -= fizzle
		visible_message(SPAN_WARNING("The fuse on \the [name] fizzles out early."))
		playsound(get_turf(src), 'sound/items/cigs_lighters/cig_snuff.ogg', 50)
		fuse_lit = FALSE
		set_light(0)
		update_icon()
		return
	else
		fuse_length += rand(-2, 2) // If the fuse isn't fizzling out or detonating instantly, make it a little harder to predict the fuse by +2/-2 seconds.
	sleep(fuse_length * 1 SECOND)

	switch(round(fuel))
		if(0)
			visible_message(SPAN_NOTICE("\The [name]'s fuse burns out and nothing happens."))
			fuse_length = 0
			fuse_lit = FALSE
			update_icon()
			set_light(0)
			return
		if(1 to FUSELENGTH_MAX) // baby explosion.
			var/obj/item/trash/can/popped_can = new(get_turf(src))
			popped_can.icon_state = icon_state
			popped_can.name = "popped can"
			playsound(get_turf(src), 'sound/effects/snap.ogg', 50)
			visible_message(SPAN_WARNING("\The [name] pops harmlessly!"))
		if(11 to 20) // slightly less baby explosion
			new /obj/item/material/shard/shrapnel(get_turf(src))
			playsound(get_turf(src), 'sound/effects/bang.ogg', 50)
			visible_message(SPAN_WARNING("\The [name] bursts violently into pieces!"))
		if(LETHAL_FUEL_CAPACITY to INFINITY) // boom
			fragem(src, shrapnelcount, shrapnelcount, 1, 0, 5, 1, TRUE, 2) // The main aim of the grenade should be to hit and wound people with shrapnel.
			playsound(get_turf(src), 'sound/effects/Explosion1.ogg', 50)
			visible_message(SPAN_DANGER("<b>\The [name] explodes!</b>"))
	fuse_lit = FALSE
	update_icon()
	qdel(src)

// can_light()
/obj/item/reagent_containers/food/drinks/cans/proc/can_light() // Just reverses the fuse_lit var to return a TRUE or FALSE.
    return !fuse_lit && fuse_length

/obj/item/reagent_containers/food/drinks/cans/proc/fuse_remove(var/cable_removed = fuse_length)
	fuse_length -= cable_removed
	update_icon()
	if(!fuse_length)
		if(bombcasing > BOMBCASING_EMPTY)
			desc = "A grenade casing with \a [name] slotted into it."
		else
			desc = initial(desc)

/obj/item/reagent_containers/food/drinks/cans/bullet_act(obj/item/projectile/P)
	if(P.firer && REAGENT_VOLUME(reagents, /singleton/reagent/fuel) >= LETHAL_FUEL_CAPACITY)
		visible_message(SPAN_DANGER("\The [name] is hit by the [P]!"))
		log_and_message_admins("shot an improvised [name] explosive", P.firer)
		log_game("[key_name(P.firer)] shot improvised grenade at [loc.loc.name] ([loc.x],[loc.y],[loc.z]).",ckey=key_name(P.firer))
	detonate(TRUE)
	. = ..()

/obj/item/reagent_containers/food/drinks/cans/ex_act(severity)
	detonate(TRUE)
	. = ..()

/obj/item/reagent_containers/food/drinks/cans/fire_act()
	if(can_light())
		fuse_lit = TRUE
		detonate(FALSE)
		visible_message(SPAN_WARNING("<b>\The [name]'s fuse catches on fire!</b>"))
	. = ..()

//
// Can Sizes
//

// 33 Centiliter Can
// Regular sodas, juice, et cetera.
/obj/item/reagent_containers/food/drinks/cans/can_33cl
	name = "can"
	desc = "A 33 cl aluminium can."
	icon_state = "can_33cl"
	center_of_mass = list("x"=16, "y"=10)
	volume = 33

// 50 Centiliter Can
// Water, energy drinks, et cetera.
/obj/item/reagent_containers/food/drinks/cans/can_50cl
	name = "can"
	desc = "A 50 cl aluminium can."
	icon_state = "can_50cl"
	center_of_mass = list("x" = 16, "y" = 8)
	can_size_overrides = list("x" = 1)
	volume = 50

//
// Drinks
//

// Carbonated Water
/obj/item/reagent_containers/food/drinks/cans/carbonated_water
	name = "\improper carbonated water can"
	desc = "A 33 cl aluminium can of carbonated water."
	sticker = "water"
	reagents_to_add = list(/singleton/reagent/water/carbonated = 33)

/obj/item/reagent_containers/food/drinks/cans/soda_water
	name = "soda water can"
	desc = "A 33 cl aluminium can of soda water."
	sticker = "soda_water"
	reagents_to_add = list(/singleton/reagent/drink/soda_water = 33)

/obj/item/reagent_containers/food/drinks/cans/tonic_water
	name = "tonic water can"
	desc = "A 33 cl aluminium can of tonic water."
	sticker = "tonic_water"
	reagents_to_add = list(/singleton/reagent/drink/tonic_water = 33)

// Starfall (Cola)
/obj/item/reagent_containers/food/drinks/cans/starfall
	name = "\improper Starfall can"
	desc = "A 33 cl aluminium can of Starfall cola."
	sticker = "starfall"
	reagents_to_add = list(/singleton/reagent/drink/starfall = 33)

// Starfall Max (Cola)
/obj/item/reagent_containers/food/drinks/cans/starfall_max
	name = "\improper Starfall Max can"
	desc = "A 33 cl aluminium can of Starfall Max cola. Contains no sugar, unless you count the sweetener as sugar."
	sticker = "starfall_max"
	reagents_to_add = list(/singleton/reagent/drink/starfall_max = 33)

// Comet Cola (Cola)
/obj/item/reagent_containers/food/drinks/cans/comet_cola
	name = "\improper Comet Cola can"
	desc = "A 33 cl aluminium can of Comet Cola."
	sticker = "comet_cola"
	reagents_to_add = list(/singleton/reagent/drink/comet_cola = 33)

// Comet Cola Zero (Cola)
/obj/item/reagent_containers/food/drinks/cans/comet_cola_zero
	name = "\improper Comet Cola Zero can"
	desc = "A 33 cl aluminium can of Comet Cola Zero. The zero sugar variant, as the name implies."
	sticker = "comet_cola_zero"
	reagents_to_add = list(/singleton/reagent/drink/comet_cola_zero = 33)

// Stellar Jolt (Lemon and Lime Soda)
/obj/item/reagent_containers/food/drinks/cans/stellar_jolt
	name = "\improper Stellar Jolt can"
	desc = "A 33 cl aluminium can of Stellar Jolt."
	sticker = "stellar_jolt"
	reagents_to_add = list(/singleton/reagent/drink/stellar_jolt = 33)

// Lemon Twist (Lemon and Lime Soda)
/obj/item/reagent_containers/food/drinks/cans/lemon_twist
	name = "\improper Lemon Twist can"
	desc = "A 33 cl aluminium can of Lemon Twist."
	sticker = "lemon_twist"
	reagents_to_add = list(/singleton/reagent/drink/lemon_twist = 33)

// Orange Sunset (Orange Soda)
/obj/item/reagent_containers/food/drinks/cans/orange_sunset
	name = "\improper Orange Sunset can"
	desc = "A 33 cl aluminium can of Orange Sunset."
	sticker = "orange_sunset"
	reagents_to_add = list(/singleton/reagent/drink/orange_sunset = 33)

// OJ Dash (Orange Soda)
/obj/item/reagent_containers/food/drinks/cans/oj_dash
	name = "\improper OJ Dash can"
	desc = "A 33 cl aluminium can of OJ Dash."
	sticker = "oj_dash"
	reagents_to_add = list(/singleton/reagent/drink/oj_dash = 33)

// Xanu Rush (Peach Soda)
/obj/item/reagent_containers/food/drinks/cans/xanu_rush
	name = "\improper Xanu Rush can"
	desc = "A 33 cl aluminium can of Xanu Rush. Made from fresh Xanu Prime peaches."
	desc_extended = "The rehabilitating environment of Xanu has allowed for small-scale agriculture to bloom. Xanu Rush is the number one Coalition soda, despite its somewhat dull taste."
	sticker = "xanu_rush"
	reagents_to_add = list(/singleton/reagent/drink/xanu_rush = 33)

// Cherry Blossom (Cherry Soda)
/obj/item/reagent_containers/food/drinks/cans/cherry_blossom
	name = "\improper Cherry Blossom can"
	desc = "A 33 cl aluminium can of Cherry Blossom."
	sticker = "cherry_blossom"
	reagents_to_add = list(/singleton/reagent/drink/cherry_blossom = 33)

// Cherry Blossom Zero (Sugar-free Cherry Blossom Soda)
/obj/item/reagent_containers/food/drinks/cans/cherry_blossom_zero
	name = "\improper Cherry Blossom Zero can"
	desc = "A 33 cl aluminium can of Cherry Blossom Zero."
	sticker = "cherry_blossom_zero"
	reagents_to_add = list(/singleton/reagent/drink/cherry_blossom_zero = 33)

// Getmore Root Beer (Sassafras Soda)
/obj/item/reagent_containers/food/drinks/cans/getmore_root_beer
	name = "\improper Getmore Root Beer"
	desc = "A 33 cl aluminium can of Getmore Root Beer. A classic Earth drink, made from sassafras roots."
	sticker = "root_beer"
	reagents_to_add = list(/singleton/reagent/drink/getmore_root_beer = 33)

// Grapevine (Grape Soda)
/obj/item/reagent_containers/food/drinks/cans/grapevine
	name = "\improper Grapevine can"
	desc = "A 33 cl aluminium can of Grapevine soda."
	sticker = "grapevine"
	reagents_to_add = list(/singleton/reagent/drink/grape_juice = 33)

// Silversun Wave (Ice Tea)
/obj/item/reagent_containers/food/drinks/cans/silversun_wave
	name = "\improper Silversun Wave ice tea can"
	desc = "A 33 cl aluminium can of Silversun Wave ice tea. Marketed as a favorite amongst parched Silversun beachgoers."
	sticker = "silversun_wave"
	reagents_to_add = list(/singleton/reagent/drink/ice_tea = 33)

// Pow2Go (Energy Drink)
/obj/item/reagent_containers/food/drinks/cans/pow2go
	name = "\improper Pow2Go can"
	desc = "A 33 cl aluminium can of Pow2Go. An extremely ill-advised combination of excessive caffeine and alcohol. Getmore's most controversial product to date."
	sticker = "pow2go"
	reagents_to_add = list(/singleton/reagent/alcohol/pow2go = 33)

//
// Non-standard Drinks
//

// Dyn Cooling Breeze (Dyn Soda)
/obj/item/reagent_containers/food/drinks/cans/dyn_cooling_breeze
	name = "\improper Dyn Cooling Breeze can"
	desc = "A 33 cl aluminium can of Dyn Cooling Breeze. One of the most refreshing things you can find on the market, based on the dyn Skrell medicinal plant."
	sticker = "dyn_cooling_breeze"
	reagents_to_add = list(/singleton/reagent/drink/dyn_juice/cold = 33)

// Hro'zamal Soda (Hro'zamal-based Soda)
/obj/item/reagent_containers/food/drinks/cans/hrozamal_soda
	name = "Hro'zamal Soda can"
	desc = "A 33 cl aluminium can of Hro'zamal Soda. Made with Hro'zamal Ras'Nifs powder and canned in the People's Republic of Adhomai."
	desc_extended = "Hro'zamal Soda is a soft drink made from the seed's powder of a plant native to Hro'zamal, the sole Hadiist colony. While initially consumed as a herbal tea by the colonists, it was introduced to Adhomai by the Army Expeditionary Force and transformed into a carbonated drink. The beverage is popular with factory workers and university students because of its stimulant effect."
	sticker = "hrozamal"
	reagents_to_add = list(/singleton/reagent/drink/hrozamal_soda = 30)

// Shouter Milk (Fermented Fatshouter Milk)
/obj/item/reagent_containers/food/drinks/cans/shouter_milk
	name = "\improper Shouter Milk can"
	desc = "A 33 cl aluminium can of fermented fatshouters milk, imported from Adhomai."
	desc_extended = "Fermend fatshouters milk is a drink that originated among the nomadic populations of Rhazar'Hrujmagh, and it has spread to the rest of Adhomai."
	sticker = "shouter_milk"
	reagents_to_add = list(/singleton/reagent/drink/milk/adhomai/fermented = 33)

// Hakhma Milk (Hahkma Bettle Milk)
/obj/item/reagent_containers/food/drinks/cans/hakhma_milk
	name = "\improper Hakhma Milk can"
	desc = "A 33 cl aluminium can of Hakhma beetle milk, sourced from Scarab and Drifter communities."
	sticker = "hakhma_milk"
	reagents_to_add = list(/singleton/reagent/drink/milk/beetle = 33)

// Three Towns Cider (Non-descript Butanol-based Cider)
/obj/item/reagent_containers/food/drinks/cans/three_towns_cider
	name = "\improper Three Towns Cider can"
	desc = "A 33 cl aluminium can of Three Towns Cider. A cider made on the west coast of the Moghresian Sea, this is simply one of many brands made in a region known for its craft local butanol, shipped throughout the Wasteland.<br>" + SPAN_DANGER("WARNING: CONTAINS BUTANOL. INTENDED FOR UNATHI CONSUMPTION ONLY.")
	sticker = "three_towns_cider"
	reagents_to_add = list(/singleton/reagent/alcohol/butanol/three_towns_cider = 33)

// Phoron Punch (Phoron-based Punch)
/obj/item/reagent_containers/food/drinks/cans/phoron_punch
	name = "\improper Phoron Punch can"
	desc = "A 33 cl aluminium can of Phoron Punch. " + SPAN_DANGER("WARNING: CONTAINS PHORON. INTENDED FOR VAURCAE CONSUMPTION ONLY. CONSUMPTION OF THIS PRODUCT AS NON-VAURCAE WILL LEAD TO DEATH.")
	sticker = "phoron_punch"
	reagents_to_add = list(/singleton/reagent/water = 18, /singleton/reagent/kois/clean = 10, /singleton/reagent/toxin/phoron = 5)

//
// Zo'ra Sodas
//

// Zo'ra Soda Parent Item
/obj/item/reagent_containers/food/drinks/cans/zora_soda
	name = "\improper Zo'ra Soda parent item"
	desc = DESC_PARENT
	reagents_to_add = list(/singleton/reagent/drink/zora_soda = 50)

// Zo'ra Soda Cherry
/obj/item/reagent_containers/food/drinks/cans/zora_soda/cherry
	name = "\improper Zo'ra Soda Cherry can"
	desc = "A 50 cl aluminium can of cherry flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, all good energy drinks come in cherry."
	sticker = "zora_cherry"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/cherry = 50)

// Zo'ra Soda Phoron Passion
/obj/item/reagent_containers/food/drinks/cans/zora_soda/phoron_passion
	name = "\improper Zo'ra Soda Phoron Passion can"
	desc = "A 50 cl aluminium can of grape flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, it actually doesn't taste like phoron but rather like grape."
	sticker = "zora_phoron_passion"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/phoron_passion = 50)

// Zo'ra Soda Energy Crush
/obj/item/reagent_containers/food/drinks/cans/zora_soda/energy_crush
	name = "\improper Zo'ra Soda Energy Crush can"
	desc = "A 50 cl aluminium can of nitrogen-infused creamy orange zest flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, the smooth taste is engineered to near perfection."
	sticker = "zora_energy_crush"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/energy_crush = 50)

// Zo'ra Soda Rockin' Raspberry
/obj/item/reagent_containers/food/drinks/cans/zora_soda/rockin_raspberry
	name = "\improper Zo'ra Soda Rockin' Raspberry can"
	desc = "A 50 cl aluminium can of \"blue raspberry\" flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, it tastes like a more flowery and aromatic raspberry."
	sticker = "zora_rockin_raspberry"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/rockin_raspberry = 50)

/obj/item/reagent_containers/food/drinks/cans/zora_soda/sour_venom_grass
	name = "\improper Zo'ra Soda Sour Venom Grass can"
	desc = "A 50 cl aluminium can of sour \"venom grass\" flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, it tastes like a cloud of angry stinging acidic bees."
	sticker = "zora_sour_venom_grass"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/sour_venom_grass = 50)

/obj/item/reagent_containers/food/drinks/cans/zora_soda/hozm // "Contraband"
	name = "\improper Zo'ra Soda High Octane Zorane Might can"
	desc = "A 50 cl aluminium can of mint flavoured Zo'ra Soda energy drink, with a lot of V'krexi additives. According to the label, it tastes like impaling the roof of your mouth with a freezing cold spear laced with angry bees and road salt."
	sticker = "zora_hozm"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/hozm = 50)

/obj/item/reagent_containers/food/drinks/cans/zora_soda/kois_twist
	name = "\improper Zo'ra Soda K'ois Twist can"
	desc = "A 50 cl aluminium can of K'ois-imitation flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, it contains no K'ois but rather a flavour that imitates it."
	sticker = "zora_kois_twist"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/kois_twist = 50)

/obj/item/reagent_containers/food/drinks/cans/zora_soda/drone_fuel
	name = "\improper Zo'ra Soda Drone Fuel can"
	desc = "A 50 cl aluminium can of industrial fluid flavoured Zo'ra Soda energy drink, with V'krexi additives. According to the label, it is meant for Vaurcae and reinforces this by the big red text that says \"" + SPAN_DANGER("WARNING: Known to induce vomiting in all species except vaurcae and dionae.") + "\"."
	sticker = "zora_drone_fuel"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/drone_fuel = 50)

/obj/item/reagent_containers/food/drinks/cans/zora_soda/royal_jelly
	name = "\improper Zo'ra Soda Royal Jelly can"
	desc = "A 50 cl aluminium can of royal jelly infused Zo'ra Soda energy drink, with V'krexi additives. According to the label, it has a mild stimulating effect."
	desc_extended = "Royal jelly is a nutritious concentrated substance commonly created by caretaker Vaurcae in order to feed larvae. It is known to have a stimulating effect in most, if not all, species."
	sticker = "zora_royal_jelly"
	reagents_to_add = list(/singleton/reagent/drink/zora_soda/royal_jelly = 50)

// Undefines
#undef LETHAL_FUEL_CAPACITY
#undef FUSELENGTH_MAX
#undef FUSELENGTH_MIN
#undef FUSELENGTH_SHORT
#undef FUSELENGTH_LONG
#undef BOMBCASING_EMPTY
#undef BOMBCASING_LOOSE
#undef BOMBCASING_SECURE