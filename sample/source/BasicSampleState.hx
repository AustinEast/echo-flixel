import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.FlxState;
import echo.util.verlet.Verlet;

using echo.FlxEcho;

class BasicSampleState extends FlxState {

  var objects:FlxGroup;
  var object_count:Int = 50;

  override function create() {
    super.create();

    // Initialize  FlxEcho
    FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 20});

    // Draw the debug scene so we can see the Echo bodies
    FlxEcho.draw_debug = true;

    // Create a normal FlxGroup
    objects = new FlxGroup();

    // Create all the FlxObjects and their Echo bodies
    for (i in 0...object_count) {
      // Create a normal FlxObject
      var object = new FlxObject();

      var scale = FlxG.random.float(0.3, 1);

      // Add a body to the object
      object.add_body({
        x: FlxG.random.float(60, FlxG.width - 60),
        y: FlxG.random.float(0, FlxG.height / 2),
        elasticity: 0.7,
        rotation: FlxG.random.float(0, 360),
        shape: {
          type: POLYGON,
          radius:FlxG.random.float(16, 32),
          width: FlxG.random.float(16, 48),
          height: FlxG.random.float(16, 48),
          sides: FlxG.random.int(3, 8),
          scale_x: scale,
          scale_y: scale
        }
      });

      // Add the object to the FlxGroup
      // NOTE! - This must be used instead of the normal way of adding objects to FlxGroups (ie - `objects.add(object);`)
      object.add_to_group(objects);
    }

    // Add a Listener to collide all FlxObjects
    FlxEcho.listen(objects, objects);

    //  Add a Verlet Rope, just for fun!
    FlxEcho.instance.verlet.add(Verlet.rope([for (i in 0...10) new echo.math.Vector2(80 + i * 10, 70)], 0.7, [0]));
  }
}