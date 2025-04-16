@tool
extends Control

enum CollisionType {
	Convex,
	Multiple,
	Trimesh
}

enum FormatType {
	GLTF,
	FBX,
	OBJ
}

var RB_mass:float=1
var RB_Gravity:float=1
var CCD:bool=false
var default_collision: CollisionType = CollisionType.Convex
var default_format_type: FormatType = FormatType.GLTF

var convex_collision_simplified: bool = false
var multiple_convex_collisions_custom_settings: bool = false
var resetPos=false
var Collision_layers:Array[int]
var Mask_layers:Array[int]


func _ready() -> void:
	Collision_layers.push_back(1)
	#Collision_layers.push_back(5)
	AddSelectedLayersButton(%layerContainer)

	Mask_layers.push_back(1)
	#Mask_layers.push_back(5)
	AddSelectedMaskLayersButton(%MasklayerContainer)
func CreateRigidBody():
	var editor_selection = EditorInterface.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()	

	for i in range(selected_nodes.size()):
		
		var newRB#=RB_ADDON.instantiate()
		newRB=RigidBody3D.new()
		newRB.continuous_cd=CCD
		newRB.mass=RB_mass
		newRB.gravity_scale=RB_Gravity
		#selected_nodes[0].add_child(newRB)
		var MyName:String=selected_nodes[i].name+"RB_Addon"
		newRB.name=MyName
		SetCollisionLayers(newRB)
		SetMaskCollisionLayers(newRB)
	#add_child(newRB)
	#selected_nodes[0].add_child(newRB)
	#newRB.set_owner(selected_nodes[0])
		# add rigid body3d to scene
		get_tree().get_edited_scene_root().add_child(newRB)
		newRB.set_owner(get_tree().get_edited_scene_root())
		var old_node=selected_nodes[i]#.duplicate()
		#set nodes position
		newRB.global_position=old_node.global_position
		old_node.reparent(newRB,false)
		old_node.position=Vector3.ZERO
		
		if selected_nodes[i] is MeshInstance3D:
			#get The Collision Reff
			var collReff=create_selected_collision(old_node)
			#get static body leftover to variable
			var StaticBody_levtover=collReff.get_parent()
			#move the collision to rigid body 3d
			collReff.reparent(newRB,false)
			#delete the static body leftover
			StaticBody_levtover.queue_free()
		elif selected_nodes[i] is Node3D:
			
			var parent = selected_nodes[i].get_tree().get_edited_scene_root()
			parent.set_editable_instance(selected_nodes[i], true);
			#get all children of the FBX or BLEND or GLTF file
			var meshesChillds=selected_nodes[i].get_children()
			if meshesChillds.size()==0:
				printerr(selected_nodes[i].name," dont contain eny meshes")
				return
			for a in range(meshesChillds.size()):
				
				if meshesChillds[a] is MeshInstance3D:
					#create collision
					
					
					var collReff:CollisionShape3D=create_selected_collision(meshesChillds[a])
					var newCollisionToCopy=CollisionShape3D.new()
					newCollisionToCopy.name="Colision "+meshesChillds[a].name
					newCollisionToCopy.shape=collReff.shape
					#newRB.scale=selected_nodes[i].scale
					
					
					#newCollisionToCopy.position=meshesChillds[a].position
					#newCollisionToCopy.scale=meshesChillds[a].scale
					#newCollisionToCopy.rotation=meshesChillds[a].rotation+selected_nodes[i].rotation
					get_tree().get_edited_scene_root().add_child(newCollisionToCopy)
					newCollisionToCopy.set_owner(get_tree().get_edited_scene_root())

					newCollisionToCopy.reparent(newRB,false)
					#newRB.scale=selected_nodes[i].scale
					newCollisionToCopy.global_position=collReff.global_position
					newCollisionToCopy.rotation=meshesChillds[a].rotation+selected_nodes[i].rotation
					newCollisionToCopy.scale=meshesChillds[a].scale*selected_nodes[i].scale
					#take the perant static body do delete it reff
					var StaticBody_levtover=collReff.get_parent()
					#collReff.reparent(newRB,false)
					StaticBody_levtover.queue_free()
			#selected_nodes[i].scale=Vector3(1,1,1)
			
			#print(collReff.name)
			#match(default_collision):
		#CollisionType.Convex:
			#mesh.create_convex_collision(false, convex_collision_simplified)
		#CollisionType.Multiple:
			#mesh.create_multiple_convex_collisions()
		#CollisionType.Trimesh:
			#mesh.create_trimesh_collision()
		
		#get_tree().get_edited_scene_root().remove_child(selected_nodes[i])
		#selected_nodes[i].replace_by(newRB,true)
		#get_tree().get_edited_scene_root().move_child(old_node,position+1)
		#newRB.add_child(old_node)
		#old_node.set_owner(newRB)

func RemoveRigidBody():
	var editor_selection = EditorInterface.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()	

	for i in range(selected_nodes.size()):
		var childerns=selected_nodes[i].get_children()
		for aa in range(childerns.size()):#maybe reverse loop
			if childerns[aa] is CollisionShape3D:
				childerns[aa].queue_free()
					
		for aa in range(childerns.size()):#maybe reverse loop
			if childerns[aa] is Node3D:
				childerns[aa].reparent(selected_nodes[i].get_parent(),false)
		selected_nodes[i].queue_free()
				
func MyCreateCollision():
	var editor_selection = EditorInterface.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()
	

	#print("%s node selected"%selected_nodes.size())
	
	for i in range(selected_nodes.size()):
		if selected_nodes[i] is MeshInstance3D:
			create_selected_collision(selected_nodes[i])
			if resetPos:
				selected_nodes[i].global_position=Vector3.ZERO
				#if the node is 3d Mesh file like FBX
		elif selected_nodes[i] is Node3D:
		#set editable childrens
			var parent = selected_nodes[i].get_tree().get_edited_scene_root()
			parent.set_editable_instance(selected_nodes[i], true);
			
			var children=selected_nodes[i].get_children()
			if children.size()==0:
				printerr("3d node do not contain mesh")
			for meshs in range(children.size()):
				#print(children[meshs].name)
				if children[meshs] is MeshInstance3D:
		
				# create static bodi and collision to copy from
					var collReff=create_selected_collision(children[meshs])
					#create the real collision (becose the firs is not in the scebe
					var NewColl=CollisionShape3D.new()
					NewColl.name="Colision "+selected_nodes[i].name
					NewColl.shape=collReff.shape
					NewColl.rotation=children[meshs].rotation+selected_nodes[i].rotation
					#NewColl.position=children[meshs].position
					#NewColl.scale=children[meshs].scale
					#add the collision to the scene
					get_tree().get_edited_scene_root().add_child(NewColl)
					NewColl.set_owner(get_tree().get_edited_scene_root())
				#create real static body
					var newSB=StaticBody3D.new()
					SetCollisionLayers(newSB)
					SetMaskCollisionLayers(newSB)
					newSB.scale=children[meshs].scale*selected_nodes[i].scale
					newSB.name="StaticBody"+children[meshs].name+str(randi_range(0,500))
					get_tree().get_edited_scene_root().add_child(newSB)
					newSB.set_owner(get_tree().get_edited_scene_root())
					newSB.reparent(children[meshs])
					#reparent real collision to real static body
					NewColl.reparent(newSB,false)
					newSB.position=Vector3.ZERO
					#remove the fake no good collision
					var childSB=children[meshs].get_child(0)
					if childSB is StaticBody3D:
						childSB.queue_free()


				else:
					printerr("3d node do not contain mesh")
			if resetPos:
				selected_nodes[i].global_position=Vector3.ZERO
				
				
func SetCollisionLayers(object_reff):
	#var sb:=StaticBody3D.new()
	object_reff.set_collision_layer_value(1,false)
	for i in range(Collision_layers.size()):
		object_reff.set_collision_layer_value(Collision_layers[i],true)
func SetMaskCollisionLayers(object_reff):
	#var sb:=StaticBody3D.new()
	object_reff.set_collision_mask_value(1,false)
	
	for i in range(Mask_layers.size()):
		object_reff.set_collision_mask_value(Mask_layers[i],true)
	
func RemoveCollision():
	var editor_selection = EditorInterface.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()
	for i in range(selected_nodes.size()):
		if selected_nodes[i] is MeshInstance3D:
			var FirstChild=selected_nodes[i].get_children()[0]#the mesh
			if FirstChild is StaticBody3D:
				selected_nodes[i].remove_child(FirstChild)
		
		elif selected_nodes[i] is Node3D:
			
			var childerens=selected_nodes[i].get_children()
			
			for aaa in range(childerens.size()):
				if childerens[aaa].get_child(0) is StaticBody3D:
					childerens[aaa].get_child(0).queue_free()
			
			#var FirstChild=selected_nodes[i].get_children()[0]#the mesh
			#var SecondChild=FirstChild.get_children()[0]#the collision
			#if SecondChild is StaticBody3D:
				#FirstChild.remove_child(SecondChild)

	
	
	
func create_selected_collision(mesh: MeshInstance3D):
	match(default_collision):
		CollisionType.Convex:
			mesh.create_convex_collision(false, convex_collision_simplified)
		CollisionType.Multiple:
			mesh.create_multiple_convex_collisions()
		CollisionType.Trimesh:
			mesh.create_trimesh_collision()
		_:
			printerr("Error: Something goes wrong.")
	#return The Collision
	var meshChildes=mesh.get_children()
	#print(meshChildes)
	for i in range(meshChildes.size()):
		print(meshChildes[i].name)
		if meshChildes[i] is StaticBody3D:

			var SB=meshChildes[i]
			var StaticBodyChilds=SB.get_children()
			for d in range(StaticBodyChilds.size()):
				if StaticBodyChilds[d] is CollisionShape3D:
					print(StaticBodyChilds[d].name)

					return StaticBodyChilds[d]
	#return mesh.get_child(0).get_child(0)


func _on_item_list_item_selected(index: int) -> void:
	if index == 0:
		default_collision = CollisionType.Trimesh
	elif index == 1:
		default_collision = CollisionType.Convex
		convex_collision_simplified=false
	elif index == 2:
		default_collision = CollisionType.Convex
		convex_collision_simplified=true
	elif index ==3:
		default_collision =CollisionType.Multiple




func _on_create_collision_pressed() -> void:
	MyCreateCollision()


func _on_remove_pressed() -> void:
	RemoveCollision()


func _on_check_box_toggled(toggled_on: bool) -> void:
	resetPos=toggled_on


func _on_create_rb_pressed() -> void:
	CreateRigidBody()


func _on_spin_box_value_changed(value: float) -> void:
	RB_Gravity=value


func _on_mass_sb_value_changed(value: float) -> void:
	RB_mass=value


func _on_ccd_cb_toggled(toggled_on: bool) -> void:
	CCD=toggled_on


func _on_create_rb_2_pressed() -> void:
	RemoveRigidBody()

const LAYER_BUTTON_CHILD = preload("res://addons/instance_collision_and_rigidbody/LayerButtonChild.tscn")
func AddSelectedLayersButton(parent_node):
	#var children=get_children(parent_node)
	ClearAllChildern(parent_node)
	for i in range(Collision_layers.size()):
		var newBTN=LAYER_BUTTON_CHILD.instantiate()
		newBTN.text=str(Collision_layers[i])
		parent_node.add_child(newBTN)
func AddSelectedMaskLayersButton(parent_node):
	#var children=get_children(parent_node)
	ClearAllChildern(parent_node)
	for i in range(Mask_layers.size()):
		var newBTN=LAYER_BUTTON_CHILD.instantiate()
		newBTN.text=str(Mask_layers[i])
		parent_node.add_child(newBTN)
var layerSpinBoxVal:int=2
var MasklayerSpinBoxVal:int=2

func _on_layer_spin_box_value_changed(value: float) -> void:
	layerSpinBoxVal=int(value)


func _on_add_layer_btn_pressed() -> void:
	if not Collision_layers.has(layerSpinBoxVal):
		Collision_layers.push_back(layerSpinBoxVal)
		AddSelectedLayersButton(%layerContainer)
func ClearAllChildern(OBJ):
	if OBJ:
		for i in range(OBJ.get_child_count(),0,-1):
			OBJ.remove_child(OBJ.get_child(i-1))
func RemoveLayer(nomber):
	if Collision_layers.has(nomber):
		Collision_layers.erase(nomber)
		AddSelectedLayersButton(%layerContainer)


func _on_del_layer_btn_2_pressed() -> void:
	RemoveLayer(layerSpinBoxVal)


func _on_add_mask_layer_btn_pressed() -> void:
	if not Mask_layers.has(MasklayerSpinBoxVal):
		Mask_layers.push_back(MasklayerSpinBoxVal)
		AddSelectedMaskLayersButton(%MasklayerContainer)


func _on_del_mask_layer_btn_2_pressed() -> void:
	if Mask_layers.has(MasklayerSpinBoxVal):
		Mask_layers.erase(MasklayerSpinBoxVal)
		AddSelectedMaskLayersButton(%MasklayerContainer)


func _on_masklayer_spin_box_value_changed(value: float) -> void:
	MasklayerSpinBoxVal=int(value)
