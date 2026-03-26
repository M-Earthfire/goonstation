TYPEINFO(/datum/component/chempipe_interface)
	initialization_args = list(
		ARG_INFO("proc_on_connect", DATA_INPUT_REF, "The proc reference that will be called AFTER the component replaced a port with a connecting_node"),
		ARG_INFO("proc_on_disconnect", DATA_INPUT_REF, "The proc reference that will be called BEFORE the component replaces connecting_node with a port"),
		ARG_INFO("proc_on_process", DATA_INPUT_REF, "The proc reference that will be called when the chemical node processes"),
	)

///This component is intended for 1-tile sized objects to be able to be easily connected by placing a fluid pipe port on their tile.
///This component will replace the fluid port with a unary node that and will relay signals between the machine in question and the port
///This component will take care that the node gets replaced with a fluid port again whenever it's parent gets moved, destroyed or when this component is removed.

/datum/component/chempipe_interface
	dupe_mode = COMPONENT_DUPE_UNIQUE // we don't want a new component initiallizing over the old one to delete an already existing fluid pipe node
	/// This the fluid node that will replace the build interface
	var/obj/machinery/fluid_machinery/unary/node/connecting_node = null
	/// This stores the underlay under the machine
	var/image/node_underlay = null
	/// This stores the turf this component is scanning for a fluid port
	var/turf/scanned_turf = null
	///The Procref that will get called after the node replaced a port
	var/on_connect_proc = null
	///The Procref that will get called before the node gets replaced by a port
	var/on_disconnect_proc = null
	///The Procref that will get called when the node processes
	var/on_process_proc = null



/datum/component/chempipe_interface/Initialize(var/connect_proc, var/disconnect_proc, var/process_proc)
	. = ..()
	if(!src.parent || !isatom(src.parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/new_parent = src.parent
	src.on_connect_proc = connect_proc
	src.on_disconnect_proc = disconnect_proc
	src.on_process_proc = process_proc
	//maybe we are stuck somewhere like e.g. a frame, so we need to account for that
	if(isturf(new_parent.loc))
		src.scanned_turf = get_turf(new_parent.loc)


/datum/component/chempipe_interface/RegisterWithParent()
	. = ..()
	var/atom/affected_parent = src.parent
	RegisterHelpMessageHandler(affected_parent, PROC_REF(get_help_msg))
	if(src.scanned_turf)
		RegisterSignal(src.scanned_turf, COMSIG_TURF_FLUID_PORT_CREATED, PROC_REF(on_fluid_port_created))
	if(ismovable(src.parent))
		RegisterSignal(src.parent, COMSIG_MOVABLE_SET_LOC, PROC_REF(on_parent_move))


/datum/component/chempipe_interface/UnregisterFromParent()
	. = ..()
	var/atom/affected_parent = src.parent
	UnregisterHelpMessageHandler(affected_parent)
	UnregisterSignal(affected_parent, COMSIG_MOVABLE_SET_LOC)
	if(src.scanned_turf)
		UnregisterSignal(src.scanned_turf, COMSIG_TURF_FLUID_PORT_CREATED)
		src.scanned_turf = null
	//when we get unregistered from our parent, we can't keep the fluid node in us.
	src.recreate_port(src.scanned_turf)
	QDEL_NULL(src.node_underlay)


/// ----------------------- Signal-related Procs -----------------------

/datum/component/chempipe_interface/proc/on_fluid_port_created(var/affected_turf, var/obj/machinery/fluid_machinery/unary/input/new_fluid_port)
	// we got a port played on our tile, let's try to grab it
	return src.replace_port(new_fluid_port)

/datum/component/chempipe_interface/proc/get_help_msg(atom/movable/viewed_parent, mob/viewer, list/lines)
	if(src.connecting_node)
		lines += "[viewed_parent] can be disconnected from the fluid network by using a HPD's remove-mode on it."
	else
		lines += "[viewed_parent] can be connected to a fluid network by placing a fluid port under it."

/datum/component/chempipe_interface/proc/on_parent_move(var/affected_parent, var/previous_location)
	var/atom/moved_parent = src.parent
	if(src.connecting_node && previous_location != moved_parent.loc)
		// if we changed our location and we had a connected node, we need to remove the location
		src.recreate_port(get_turf(previous_location))
		if(src.scanned_turf)
			UnregisterSignal(src.scanned_turf, COMSIG_TURF_FLUID_PORT_CREATED)
			src.scanned_turf = null
		if(isturf(moved_parent.loc))
			src.scanned_turf = moved_parent.loc
			RegisterSignal(src.scanned_turf, COMSIG_TURF_FLUID_PORT_CREATED, PROC_REF(on_fluid_port_created))

/datum/component/chempipe_interface/proc/on_node_process(var/obj/machinery/fluid_machinery/unary/node/processing_node, var/mult)
	if(!src.on_process_proc)
		return
	//we just return the proc we need to call on our parent
	return call(src.parent, src.on_process_proc)(src.parent, src.connecting_node, mult)

/// ----------------------- -----------------------

/// This proc removes the internal unary fluid node and places a fluid port at port_destination, if an internal fluid node exists, removing the old one
/// Returns TRUE if the fluid port was set sucessfully
/datum/component/chempipe_interface/proc/recreate_port(var/turf/port_destination)
	if(!src.connecting_node)
		return
	if(src.on_disconnect_proc)
		call(src.parent, src.on_disconnect_proc)(src.parent, src.connecting_node, port_destination)
	var/port_direction = src.connecting_node.dir
	UnregisterSignal(src.connecting_node, COMSIG_MACHINERY_PROCESS)
	QDEL_NULL(src.connecting_node)
	if(port_destination && !src.parent.qdeled && !src.parent.disposed)
		//after we removed the old fluid node, we can place a fluid port at the new direction
		//the preloader is needed because else we aren't able to set a direction within new()
		new /dmm_suite/preloader(port_destination, list("dir" = port_direction))
		new /obj/machinery/fluid_machinery/unary/input(port_destination)
		src.update_overlay()
		return TRUE


/// This proc replaces a given port with an internal unary fluid node
/// This proc returns TRUE if the port in question was sucessfully replaced
/datum/component/chempipe_interface/proc/replace_port(var/obj/machinery/fluid_machinery/unary/input/port_to_replace)
	if(!istype(port_to_replace) || src.connecting_node)
		return
	//we save the location so we can set the new node to that location once we removed the port
	var/port_direction = port_to_replace.dir
	port_to_replace.onDestroy()
	//the preloader is needed because else we aren't able to set a direction within new()
	new /dmm_suite/preloader(get_turf(src.parent), list("dir" = port_direction))
	src.connecting_node = new /obj/machinery/fluid_machinery/unary/node (get_turf(src.parent))
	if(src.on_connect_proc)
		call(src.parent, src.on_connect_proc)(src.parent, src.connecting_node)
	if(src.on_process_proc)
		RegisterSignal(src.connecting_node, COMSIG_MACHINERY_PROCESS, PROC_REF(on_node_process))
	src.update_overlay()
	return TRUE

/datum/component/chempipe_interface/proc/update_overlay()
	var/atom/affected_parent = src.parent
	if(!affected_parent)
		//why the fuck is the parent not an atom? Remember me to make init crash when that is the case.
		return
	if(!src.connecting_node)
		if(src.node_underlay)
			// our node got removed, so we don't have an overlay anymore
			affected_parent.overlays -= src.node_underlay
			QDEL_NULL(src.node_underlay)
		return
	if(!src.node_underlay)
		src.node_underlay = image(icon = 'icons/obj/fluidpipes/fluid_machines.dmi',loc = src.parent, layer = "node", dir = src.connecting_node.dir)
	if(!(src.node_underlay in affected_parent.overlays))
		affected_parent.underlays += src.node_underlay


