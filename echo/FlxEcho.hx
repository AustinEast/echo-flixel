package echo;

import echo.util.verlet.Verlet;
import echo.Body;
import echo.Echo;
import echo.World;
import echo.data.Options.BodyOptions;
import echo.data.Options.ListenerOptions;
import echo.data.Options.WorldOptions;
import echo.util.AABB;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject.*;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;

using Math;
using Std;
using echo.math.Vector2;

#if FLX_DEBUG
import echo.util.Debug.OpenFLDebug;
import flixel.system.ui.FlxSystemButton;
import openfl.display.BitmapData;
#end

class FlxEcho extends FlxBasic
{
	/**
	 * Gets the FlxEcho instance, which contains the current Echo World. May be Null if `FlxEcho.init` has not been called.
	 */
	public static var instance(default, null):FlxEcho;

	/**
	 * Toggles whether the physics simulation updates or not.
	 */
	public static var updates:Bool;

	/**
	 * Set this to `true` to have each physics body's acceleration reset after updating the physics simulation. Useful if you want to treat acceleration as a non-constant force.
	 */
	public static var reset_acceleration:Bool;

	/**
	 * Toggles whether the physics' debug graphics are drawn. Also Togglable through the Flixel Debugger (click the "E" icon). If Flixel isnt ran with Debug mode, this does nothing.
	 */
	public static var draw_debug(default, set):Bool;

	public var world(default, null):World;
	public var verlet(default, null):Verlet;
	public var groups:Map<FlxGroup, Array<Body>>;
	public var bodies:Map<FlxObject, Body>;

	#if FLX_DEBUG
	public static var debug_drawer:OpenFLDebug;

	static var draw_debug_button:FlxSystemButton;

	static var icon_data = [
		[0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0], [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0], [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0], [0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]];
	#end

	/**
	 * Init the Echo physics simulation
	 * @param options The attributes that define the physics `World`
	 * @param force Set to `true` to force the physics `World` to get recreated
	 */
	public static function init(options:WorldOptions, force:Bool = false)
	{
		if (force && instance != null)
		{
			FlxG.plugins.remove(instance);
			FlxG.signals.preStateSwitch.remove(on_state_switch);
			instance.destroy();
			instance = null;
		}

		if (instance == null)
		{
			#if (flixel >= "5.6.0")
			FlxG.plugins.addPlugin(instance = new FlxEcho(options));
			#else
			FlxG.plugins.add(instance = new FlxEcho(options));
			#end
			FlxG.signals.preStateSwitch.add(on_state_switch);
		}

		updates = true;
		reset_acceleration = false;

		#if FLX_DEBUG
		var icon = new BitmapData(11, 11, true, FlxColor.TRANSPARENT);
		for (y in 0...icon_data.length) for (x in 0...icon_data[y].length) if (icon_data[y][x] > 0) icon.setPixel32(x, y, FlxColor.WHITE);
		if (draw_debug_button == null)
		{
			draw_debug_button = FlxG.debugger.addButton(RIGHT, icon, () -> draw_debug = !draw_debug, true, true);
		}
		draw_debug = draw_debug;
		#end
	}

	/**
	 * Add physics body to FlxObject
	 */
	public static function add_body(object:FlxObject, ?options:BodyOptions):Body
	{
		var old_body = instance.bodies.get(object);
		if (old_body != null)
		{
			old_body.dispose();
		}

		if (options == null) options = {};
		if (options.x == null) options.x = object.x + object.width * 0.5;
		if (options.y == null) options.y = object.y + object.height * 0.5;
		if (options.shape == null && options.shapes == null && options.shape_instance == null && options.shape_instances == null) options.shape = {
			type: RECT,
			width: object.width,
			height: object.height
		}
		var body = new Body(options);
		body.object = object;
		instance.bodies.set(object, body);
		instance.world.add(body);
		return body;
	}

	/**
	 * Adds FlxObject to FlxGroup, and the FlxObject's associated physics body to the FlxGroup's associated physics group
	 */
	public inline static function add_to_group(object:FlxObject, group:FlxGroup)
	{
		group.add(object);
		if (!instance.groups.exists(group)) instance.groups.set(group, []);
		if (instance.bodies.exists(object)) instance.groups[group].push(instance.bodies[object]);
	}

	/**
	 * Creates a physics listener
	 */
	public static function listen(a:FlxBasic, b:FlxBasic, ?options:ListenerOptions)
	{
		options = get_listener_options(options);

		var a_is_object = a.isOfType(FlxObject);
		var b_is_object = b.isOfType(FlxObject);

		if (!a_is_object) add_group_bodies(cast a);
		if (!b_is_object) add_group_bodies(cast b);

		instance.world.listen(!a_is_object ? instance.groups[cast a] : instance.bodies[cast a],
			!b_is_object ? instance.groups[cast b] : instance.bodies[cast b], options);
	}

	/**
	 * Performs a one-time collision check
	 */
	public static function check(a:FlxBasic, b:FlxBasic, ?options:ListenerOptions)
	{
		options = get_listener_options(options);

		var a_is_object = a.isOfType(FlxObject);
		var b_is_object = b.isOfType(FlxObject);

		if (!a_is_object) add_group_bodies(cast a);
		if (!b_is_object) add_group_bodies(cast b);

		instance.world.check(!a_is_object ? instance.groups[cast a] : instance.bodies[cast a],
			!b_is_object ? instance.groups[cast b] : instance.bodies[cast b], options);
	}

	/**
	 * Get the physics body associated with a FlxObject
	 */
	public static inline function get_body(object:FlxObject):Body
		return instance.bodies[object];

	/**
	 * Sets a physics body to a FlxObject
	 */
	public static function set_body(object:FlxObject, body:Body):Body
	{
		var old_body = instance.bodies.get(object);
		if (old_body != null)
		{
			old_body.dispose();
			old_body.object = null;
		}

		body.object = object;
		instance.bodies.set(object, body);
		instance.world.add(body);
		return body;
	}

	/**
	 * Removes the physics body from the simulation
	 */
	public static function remove_body(body:Body):Bool
	{
		for (o => b in instance.bodies) if (b == body)
		{
			body.remove();
			instance.bodies.remove(o);
			return true;
		}

		return false;
	}

	/**
	 * Get the FlxObject associated with a physics body
	 */
	public static function get_object(body:Body):FlxObject
	{
		return body.object;
	}

	/**
	 * Removes (and optionally disposes) the physics body associated with the FlxObject
	 */
	public static function remove_object(object:FlxObject, dispose:Bool = true):Bool
	{
		var body = instance.bodies.get(object);
		if (body == null) return false;

		if (dispose)
		{
			body.dispose();
			body.object = null;
		}

		return instance.bodies.remove(object);
	}

	/**
	 * Associates a FlxGroup to a physics group
	 */
	public static inline function add_group_bodies(group:FlxGroup)
	{
		if (!instance.groups.exists(group)) instance.groups.set(group, []);
	}

	/**
	 * Gets a FlxGroup's associated physics group
	 */
	public static inline function get_group_bodies(group:FlxGroup):Null<Array<Body>>
	{
		return instance.groups.get(group);
	}

	/**
	 * Removes the FlxGroup's associated physics group from the simulation
	 */
	public static inline function remove_group_bodies(group:FlxGroup)
	{
		return instance.groups.remove(group);
	}

	/**
	 * Removes the FlxObject from the FlxGroup, and the FlxObject's associated physics body from the FlxGroup's associated physics group
	 */
	public static inline function remove_from_group(object:FlxObject, group:FlxGroup):Bool
	{
		group.remove(object);
		if (!instance.groups.exists(group) || !instance.bodies.exists(object)) return false;
		return instance.groups[group].remove(instance.bodies[object]);
	}

	/**
	 * Clears the physics world - all Bodies, Listeners, and any associated FlxObjects and FlxGroups
	 */
	public static function clear()
	{
		for (body in instance.bodies) body.dispose();
		instance.bodies.clear();
		instance.groups.clear();
		instance.world.clear();
	}

	static function get_listener_options(?options:ListenerOptions)
	{
		if (options == null) options = {};
		var temp_stay = options.stay;
		options.stay = (a, b, c) ->
		{
			if (temp_stay != null) temp_stay(a, b, c);
			if (options.separate == null || options.separate) for (col in c) {
				set_touching(get_object(a), #if (flixel >= version("6.0.0")) [CEILING.toInt(), WALL.toInt(), FLOOR.toInt()] #else [CEILING, WALL, FLOOR] #end [col.normal.dot(Vector2.up).round() + 1]);
				set_touching(get_object(b), #if (flixel >= version("6.0.0")) [CEILING.toInt(), WALL.toInt(), FLOOR.toInt()] #else [CEILING, WALL, FLOOR] #end [col.normal.negate().dot(Vector2.up).round() + 1]);
			} 
		}
		#if ARCADE_PHYSICS
		var temp_condition = options.condition;
		options.condition = (a, b, c) ->
		{
			for (col in c) square_normal(col.normal);
			if (temp_condition != null) return temp_condition(a, b, c);
			return true;
		}
		#end

		return options;
	}

	static inline function update_body_object(body:Body)
	{
		if (body.object == null) return;
		body.object.setPosition(body.x, body.y);
		if (body.object.isOfType(FlxSprite))
		{
			var sprite:FlxSprite = cast body.object;
			sprite.x -= sprite.origin.x;
			sprite.y -= sprite.origin.y;
		}
		body.object.angle = body.rotation;
		if (reset_acceleration) body.acceleration.set(0, 0);
	}

	static inline function set_touching(object:FlxObject, touching:Int)
	{
		#if (flixel >= version("6.0.0"))
		if (object.touching.toInt() & touching == 0) object.touching = FlxDirectionFlags.fromInt(object.touching.toInt() | touching);
		#else
		if (object.touching & touching == 0) object.touching = object.touching | touching;
		#end
	}

	static function square_normal(normal:Vector2)
	{
		var len = normal.length;
		var dot_x = normal.dot(Vector2.right);
		var dot_y = normal.dot(Vector2.up);
		if (dot_x.abs() > dot_y.abs()) dot_x > 0 ? normal.set(1, 0) : normal.set(-1, 0); else
			dot_y > 0 ? normal.set(0, 1) : normal.set(0, -1);
		normal.length = len;
	}

	static function on_state_switch()
	{
		clear();

		draw_debug = false;

		#if FLX_DEBUG
		if (draw_debug_button != null)
		{
			FlxG.debugger.removeButton(draw_debug_button);
			draw_debug_button = null;
		}
		#end
	}

	static function set_draw_debug(v:Bool)
	{
		#if FLX_DEBUG
		if (draw_debug_button != null) draw_debug_button.toggled = !v;

		if (v)
		{
			if (debug_drawer == null)
			{
				debug_drawer = new OpenFLDebug();
				debug_drawer.camera = AABB.get();
				debug_drawer.draw_quadtree = false;
				debug_drawer.canvas.scrollRect = null;
			}
			FlxG.addChildBelowMouse(debug_drawer.canvas);
		}
		else if (debug_drawer != null)
		{
			debug_drawer.clear();
			FlxG.removeChild(debug_drawer.canvas);
		}
		#end

		return draw_debug = v;
	}

	public function new(options:WorldOptions)
	{
		super();

		groups = [];
		bodies = [];
		world = Echo.start(options);
		verlet = new Verlet({
			width: options.width, 
			height: options.height, 
			gravity_x: options.gravity_x, 
			gravity_y: options.gravity_y
		});

		FlxG.signals.postUpdate.add(on_post_update);
		FlxG.signals.preDraw.add(on_pre_draw);
	}

	#if FLX_DEBUG
	
	@:access(flixel.FlxCamera)
	override function draw()
	{
		super.draw();

		if (!draw_debug || debug_drawer == null || world == null) return;

		// TODO - draw with full FlxG.cameras list
		debug_drawer.camera.set_from_min_max(FlxG.camera.scroll.x, FlxG.camera.scroll.y, FlxG.camera.scroll.x + FlxG.camera.width,
			FlxG.camera.scroll.y + FlxG.camera.height);

		debug_drawer.draw(world, false);
		debug_drawer.draw_verlet(verlet);

		var s = debug_drawer.canvas;
		s.x = s.y = 0;
		s.scaleX = s.scaleY = 1;
		s.rotation = FlxG.camera.angle;
		FlxG.camera.transformObject(s);
	}
	#end

	override function destroy()
	{
		super.destroy();

		FlxG.signals.postUpdate.remove(on_post_update);
		FlxG.signals.preDraw.remove(on_pre_draw);

		for (body in bodies) body.dispose();
		bodies.clear();
		groups.clear();
		world.dispose();
		verlet.dispose();

		bodies = null;
		groups = null;
		world = null;
	}

	function on_post_update()
	{
		if (updates) {
			var elapsed = FlxG.elapsed;
			world.step(elapsed);
			verlet.step(elapsed);
		}
	
		for (body in bodies) update_body_object(body);
	}

	function on_pre_draw()
	{
		#if FLX_DEBUG
		if (debug_drawer != null) debug_drawer.clear();
		#end	
	}
}
