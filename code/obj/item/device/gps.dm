var/global/list/all_GPSs = list()

/obj/item/device/gps
	name = "space GPS"
	desc = "Tells you your coordinates based on the nearest coordinate beacon."
	icon_state = "gps-off"
	item_state = "electronic"
	var/allowtrack = 1 // defaults to on so people know where you are (sort of!)
	var/serial = "4200" // shouldnt show up as this
	var/identifier = "NT13" // four characters max plz
	var/distress = 0
	var/active = 0		//probably should
	var/atom/tracking_target = null		//unafilliated with allowtrack, which essentially just lets your gps appear on other gps lists
	flags = FPRINT | TABLEPASS | CONDUCT
	w_class = 2.0
	m_amt = 50
	g_amt = 100
	mats = 2
	module_research = list("science" = 1, "devices" = 1, "miniaturization" = 8)

	proc/get_z_info(var/turf/T)
		. =  "Landmark: Unknown"
		if (!T)
			return
		if (!istype(T))
			T = get_turf(T)
		if (!T)
			return
		if (T.z == 1)
			. = "Landmark: [capitalize(station_or_ship())]"
/*			if (ismap("DESTINY"))
				. =  "Landmark: NSS Destiny"
			else if (ismap("CLARION"))
				. =  "Landmark: NSS Clarion"
			else
				. =  "Landmark: Station"
*/
		else if (T.z == 2)
			. =  "Landmark: Restricted"
		else if (T.z == 3)
			. =  "Landmark: Debris Field"
		return

	proc/show_HTML(var/mob/user)
		if (!user)
			return
		user.machine = src
		var/HTML = {"<style type="text/css">
		.desc {
			background: #21272C;
			width: calc(100% - 5px);
			padding: 2px;
		}
		.buttons a {
			display: inline-flex;
			background: #58B4DC;
			width: calc(50% - 7px);
			text-transform: uppercase;
			text-decoration: none;
			color: #fff;
			margin: 1px;
			padding: 2px 0 2px 5px;
			font-size: 11px;
		}
		.buttons.refresh a {
			padding: 1px 0 1px 5px;
			width: calc(100% - 7px);
		}
		.buttons a:hover {
			background: #6BC7E8;
		}
		.gps {
			border-top: 1px solid #58B4DC;
			background: #21272C;
			padding: 3px;
			margin: 0 0 1px 0;
			font-size: 11px;
		}
		.gps.distress {
			border-top: 2px solid #BE3737;
			background: #2C2121;
		}
		.gps.group {
			background: #58B4DC;
			margin: 0;
			font-size: 12px;
		}
		</style>"}
		HTML += build_html_gps_form(src, false, src.tracking_target)
		HTML += "<div><div class='buttons refresh'><A href='byond://?src=\ref[src];refresh=6'>(Refresh)</A></div>"
		HTML += "<div class='desc'>Each GPS is coined with a unique four digit number followed by a four letter identifier.<br>This GPS is assigned <b>[serial]-[identifier]</b>.</div><hr>"
		HTML += "<HR>"
		if (allowtrack == 0)
			HTML += "<A href='byond://?src=\ref[src];track1=2'>Enable Tracking</A>"
		if (allowtrack == 1)
			HTML += "<A href='byond://?src=\ref[src];track2=3'>Disable Tracking</A>"
		HTML += "<A href='byond://?src=\ref[src];changeid=4'>Change Identifier</A>"
		HTML += "<A href='byond://?src=\ref[src];help=5'>Toggle Distress Signal</A></div>"
		HTML += "<hr>"

		HTML += "<div class='gps group'><b>GPS Units</b></div>"
		for (var/obj/item/device/gps/G in all_GPSs)//world)
			LAGCHECK(LAG_LOW)
			if (G.allowtrack == 1)
				var/turf/T = get_turf(G.loc)
				if (!T)
					continue
				HTML += "<div class='gps [G.distress ? "distress" : ""]'><span><b>[G.serial]-[G.identifier]</b>"
				HTML += "<span style='font-size:85%;float: right'>[G.distress ? "<font color=\"red\">(DISTRESS)</font>" : "<font color=666666>(DISTRESS)</font>"]</span>"
				HTML += "<br><span>located at: [T.x], [T.y]</span><span style='float: right'>[src.get_z_info(T)]</span></span></div>"

		HTML += "<div class='gps group'><b>Tracking Implants</b></div>"
		for (var/obj/item/implant/tracking/imp in tracking_implants)//world)
			LAGCHECK(LAG_LOW)
			if (isliving(imp.loc))
				var/turf/T = get_turf(imp.loc)
				if (!T)
					continue
				HTML += "<div class='gps'><span><b>[imp.loc.name]</b><br><span>located at: [T.x], [T.y]</span><span style='float: right'>[src.get_z_info(T)]</span></span></div>"
		HTML += "<hr>"

		HTML += "<div class='gps group'><b>Beacons</b></div>"
		for (var/obj/machinery/beacon/B in machines)
			if (B.enabled == 1)
				var/turf/T = get_turf(B.loc)
				HTML += "<div class='gps'><span><b>[B.sname]</b><br><span>located at: [T.x], [T.y]</span><span style='float: right'>[src.get_z_info(T)]</span></span></div>"
		HTML += "<br></div>"

		user.Browse(HTML, "window=gps_[src];title=GPS;size=400x540;override_setting=1")
		onclose(user, "gps")

	attack_self(mob/user as mob)
		if ((user.contents.Find(src) || user.contents.Find(src.master) || get_dist(src, user) <= 1))
			src.show_HTML(user)
		else
			user.Browse(null, "window=gps_[src]")
			user.machine = null
		return

	Topic(href, href_list)
		..()
		if (usr.stat || usr.restrained() || usr.lying)
			return
		if ((usr.contents.Find(src) || usr.contents.Find(src.master) || in_range(src, usr)))
			usr.machine = src
			var/turf/T = get_turf(usr)
			if(href_list["getcords"])
				boutput(usr, "<span style=\"color:blue\">Located at: <b>X</b>: [T.x], <b>Y</b>: [T.y]</span>")
				return

			if(href_list["track1"])
				boutput(usr, "<span style=\"color:blue\">Tracking enabled.</span>")
				src.allowtrack = 1
			if(href_list["track2"])
				boutput(usr, "<span style=\"color:blue\">Tracking disabled.</span>")
				src.allowtrack = 0
			if(href_list["changeid"])
				var/t = strip_html(input(usr, "Enter new GPS identification name (must be 4 characters)", src.identifier) as text)
				if(length(t) > 4)
					boutput(usr, "<span style=\"color:red\">Input too long.</span>")
					return
				if(length(t) < 4)
					boutput(usr, "<span style=\"color:red\">Input too short.</span>")
					return
				if(!t)
					return
				src.identifier = t
			if(href_list["help"])
				if(!distress)
					boutput(usr, "<span style=\"color:red\">Sending distress signal.</span>")
					distress = 1
					//IBMNOTE: This really should be changed to use the radio system, for (x in world) sucks
					for(var/obj/item/device/gps/G in all_GPSs)//world)
						LAGCHECK(LAG_LOW)
						G.visible_message("<b>[bicon(G)] [G]</b> beeps, \"NOTICE: Distress signal recieved.\".")
				else
					distress = 0
					boutput(usr, "<span style=\"color:red\">Distress signal cleared.</span>")
					for(var/obj/item/device/gps/G in all_GPSs)//world)
						LAGCHECK(LAG_LOW)
						G.visible_message("<b>[bicon(G)] [G]</b> beeps, \"NOTICE: Distress signal cleared.\".")
			if(href_list["refresh"])
				..()

			if(href_list["dest_cords"])
				obtain_target_from_coords(href_list)
			if(href_list["stop_tracking"])
				tracking_target = null
				active = null
				icon_state = "gps-off"


			if (!src.master)
				if (ismob(src.loc))
					attack_self(src.loc)
				else
					for(var/mob/M in viewers(1, src))
						if (M.client && (M.machine == src.master || M.machine == src))
							src.attack_self(M)
			else
				if (ismob(src.master.loc))
					src.attack_self(src.master.loc)
				else
					for(var/mob/M in viewers(1, src.master))
						if (M.client && (M.machine == src.master || M.machine == src))
							src.attack_self(M)
			src.add_fingerprint(usr)
		else
			usr.Browse(null, "window=gps_[src]")
			return
		return


	New()
		..()
		serial = rand(4201,7999)
		desc += " Its serial code is [src.serial]-[identifier]."
		if (!islist(all_GPSs))
			all_GPSs = list()
		all_GPSs.Add(src)

	proc/obtain_target_from_coords(href_list)
		if (href_list["dest_cords"])
			tracking_target = null
			var/x = text2num(href_list["x"])
			var/y = text2num(href_list["y"])
			if (!x || !y)
				boutput(usr, "<span style=\"color:red\">Bad Topc call, if you see this something has gone wrong. And it's probably YOUR FAULT!</span>")
				return
			var/z = src.z
			if (src.loc)
				z = src.loc.z

			var/turf/T = locate(x,y,z)
			//Set located turf to be the tracking_target
			if (isturf(T))
				src.tracking_target = T
				boutput(usr, "<span style=\"color:blue\">Now tracking: <b>X</b>: [T.x], <b>Y</b>: [T.y]</span>")

				begin_tracking()
			else
				boutput(usr, "<span style=\"color:red\">Invalid GPS coordinates.</span>")
		sleep(10)

	proc/begin_tracking()
		if(!active)
			if (!src.tracking_target)
				usr.show_text("No target specified, cannot activate the pinpointer.", "red")
				return
			active = 1
			process()
			boutput(usr, "<span style=\"color:blue\">You activate the gps</span>")

	process()
		if(!active || !tracking_target)
			active = 0
			icon_state = "gps-off"
			return

		src.dir = get_dir(src,tracking_target)
		if (get_dist(src,tracking_target) == 0)
			icon_state = "gps-direct"
		else
			icon_state = "gps"

		SPAWN_DBG(5 DECI SECONDS) .()

	disposing()
		..()
		if (islist(all_GPSs))
			all_GPSs.Remove(src)

	disposing()
		if (islist(all_GPSs))
			all_GPSs.Remove(src)
		..()

// coordinate beacons. pretty useless but whatever you never know

/obj/machinery/beacon
	name = "coordinate beacon"
	desc = "A coordinate beacon used for space GPSes."
	icon = 'icons/obj/ship.dmi'
	icon_state = "beacon"
	var/sname = "unidentified"
	var/enabled = 1

	process()
		if(enabled == 1)
			use_power(50)

	attack_hand()
		enabled = !enabled
		boutput(usr, "<span style=\"color:blue\">You switch the beacon [src.enabled ? "on" : "off"].</span>")

	attack_ai(mob/user as mob)
		var/t = input(user, "Enter new beacon identification name", src.sname) as null|text
		if (isnull(t))
			return
		t = strip_html(replacetext(t, "'",""))
		t = copytext(t, 1, 45)
		if (!t)
			return
		src.sname = t