var/datum/antagonist/traitor/traitors

// Inherits most of its vars from the base datum.
/datum/antagonist/traitor
	id = MODE_TRAITOR
	restricted_jobs = list("Head of Security", "Captain", "Chief Engineer", "Research Director", "Chief Medical Officer", "Executive Officer", "Operations Manager", "AI", "Merchant")
	protected_jobs = list("Security Officer", "Security Cadet", "Warden", "Investigator")
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	required_age = 10

	faction = "syndicate"
	bantype = "traitor"

/datum/antagonist/traitor/New()
	..()
	traitors = src

/datum/antagonist/traitor/get_extra_panel_options(var/datum/mind/player)
	return "<a href='?src=\ref[player];common=crystals'>\[set crystals\]</a><a href='?src=\ref[src];spawn_uplink=\ref[player.current]'>\[spawn uplink\]</a>"

/datum/antagonist/traitor/Topic(href, href_list)
	if (..())
		return
	if(href_list["spawn_uplink"]) spawn_uplink(locate(href_list["spawn_uplink"]))

/datum/antagonist/traitor/can_become_antag(var/datum/mind/player)
	if(!..())
		return 0
	if(istype(player.current, /mob/living/silicon/robot/drone))
		return 0
	return 1

/datum/antagonist/traitor/create_objectives(var/datum/mind/traitor)
	if(!..())
		return

	if(istype(traitor.current, /mob/living/silicon))
		var/datum/objective/assassinate/kill_objective = new
		kill_objective.owner = traitor
		kill_objective.find_target()
		traitor.objectives += kill_objective

		var/datum/objective/survive/survive_objective = new
		survive_objective.owner = traitor
		traitor.objectives += survive_objective

		if(prob(10))
			var/datum/objective/block/block_objective = new
			block_objective.owner = traitor
			traitor.objectives += block_objective
	else
		switch(rand(1,100))
			if(1 to 33)
				var/datum/objective/assassinate/kill_objective = new
				kill_objective.owner = traitor
				kill_objective.find_target()
				traitor.objectives += kill_objective
			if(34 to 50)
				var/datum/objective/brig/brig_objective = new
				brig_objective.owner = traitor
				brig_objective.find_target()
				traitor.objectives += brig_objective
			if(51 to 66)
				var/datum/objective/harm/harm_objective = new
				harm_objective.owner = traitor
				harm_objective.find_target()
				traitor.objectives += harm_objective
			else
				var/datum/objective/steal/steal_objective = new
				steal_objective.owner = traitor
				steal_objective.find_target()
				traitor.objectives += steal_objective
		switch(rand(1,100))
			if(1 to 100)
				if (!(locate(/datum/objective/escape) in traitor.objectives))
					var/datum/objective/escape/escape_objective = new
					escape_objective.owner = traitor
					traitor.objectives += escape_objective

			else
				if (!(locate(/datum/objective/hijack) in traitor.objectives))
					var/datum/objective/hijack/hijack_objective = new
					hijack_objective.owner = traitor
					traitor.objectives += hijack_objective
	return

/datum/antagonist/traitor/equip(var/mob/living/carbon/human/traitor_mob)
	if(istype(traitor_mob, /mob/living/silicon)) // this needs to be here because ..() returns false if the mob isn't human
		add_law_zero(traitor_mob)
		if(isrobot(traitor_mob))
			var/mob/living/silicon/robot/R = traitor_mob
			R.overclock_available = TRUE
			R.emagged = TRUE
			R.verbs += /mob/living/silicon/robot/proc/ResetSecurityCodes
			R.verbs += /mob/living/silicon/robot/proc/toggle_overclock
		return 1

	if(!..())
		return 0

	traitor_mob.faction = "syndicate"
	spawn_uplink(traitor_mob)
	// Tell them about people they might want to contact.
	var/mob/living/carbon/human/M = get_poor()
	if(M && M != traitor_mob)
		to_chat(traitor_mob, "We have received credible reports that [M.real_name] might be susceptible to bribes. If you need assistance, consider contacting them.")
		traitor_mob.mind.store_memory("<b>Potential Collaborator</b>: [M.real_name]")

	//Begin code phrase.
	give_codewords(traitor_mob)

/datum/antagonist/traitor/proc/spawn_uplink(var/mob/living/carbon/human/traitor_mob)
	if(!istype(traitor_mob))
		return

	var/loc = ""
	var/obj/item/R = locate() //Hide the uplink in a PDA if available, otherwise radio

	if(traitor_mob.client.prefs.uplinklocation == "Headset")
		R = locate(/obj/item/device/radio) in traitor_mob.contents
		if(!R)
			R = locate(/obj/item/modular_computer) in traitor_mob.contents
			to_chat(traitor_mob, "Could not locate a Radio, installing in PDA instead!")
		if (!R)
			to_chat(traitor_mob, "Unfortunately, neither a radio or a PDA relay could be installed.")
	else if(traitor_mob.client.prefs.uplinklocation == "PDA")
		R = locate(/obj/item/modular_computer) in traitor_mob.contents
		if(!R)
			R = locate(/obj/item/device/radio) in traitor_mob.contents
			to_chat(traitor_mob, "Could not locate a PDA, installing into a Radio instead!")
		if(!R)
			to_chat(traitor_mob, "Unfortunately, neither a radio or a PDA relay could be installed.")
	else if(traitor_mob.client.prefs.uplinklocation == "None")
		to_chat(traitor_mob, "You have elected to not have an AntagCorp portable teleportation relay installed!")
		R = null
	else
		to_chat(traitor_mob, "You have not selected a location for your relay in the antagonist options! Defaulting to PDA!")
		R = locate(/obj/item/modular_computer) in traitor_mob.contents
		if (!R)
			R = locate(/obj/item/device/radio) in traitor_mob.contents
			to_chat(traitor_mob, "Could not locate a PDA, installing into a Radio instead!")
		if (!R)
			to_chat(traitor_mob, "Unfortunately, neither a radio or a PDA relay could be installed.")

	if(!R)
		return

	if(istype(R,/obj/item/device/radio))
		// generate list of radio freqs
		var/obj/item/device/radio/target_radio = R
		var/freq = PUBLIC_LOW_FREQ
		var/list/freqlist = list()
		while (freq <= PUBLIC_HIGH_FREQ)
			if (freq < 1451 || freq > PUB_FREQ)
				freqlist += freq
			freq += 2
			if ((freq % 2) == 0)
				freq += 1
		freq = freqlist[rand(1, freqlist.len)]
		var/obj/item/device/uplink/hidden/T = new(R, traitor_mob.mind)
		target_radio.hidden_uplink = T
		target_radio.traitor_frequency = freq
		to_chat(traitor_mob, "A portable object teleportation relay has been installed in your [R.name] [loc]. Simply dial the frequency [format_frequency(freq)] to unlock its hidden features.")
		traitor_mob.mind.store_memory("<B>Radio Freq:</B> [format_frequency(freq)] ([R.name] [loc]).")

	else if (istype(R, /obj/item/modular_computer))
		// generate a passcode if the uplink is hidden in a PDA
		var/pda_pass = "[rand(100,999)] [pick("Alpha","Bravo","Delta","Omega")]"
		var/obj/item/device/uplink/hidden/T = new(R, traitor_mob.mind)
		R.hidden_uplink = T
		T.pda_code = pda_pass
		to_chat(traitor_mob, "A portable object teleportation relay has been installed in your [R.name] [loc]. Simply enter the code \"[pda_pass]\" into the ringtone select to unlock its hidden features.")
		traitor_mob.mind.store_memory("<B>Uplink Passcode:</B> [pda_pass] ([R.name] [loc]).")

/datum/antagonist/traitor/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs. You may ignore all other laws."
	var/law_borg = "Accomplish your AI's objectives at all costs. You may ignore all other laws."
	to_chat(killer, "<b>Your laws have been changed!</b>")
	killer.set_zeroth_law(law, law_borg)
	to_chat(killer, "New law: 0. [law]")

/datum/antagonist/traitor/get_antag_radio()
	return "Mercenary"