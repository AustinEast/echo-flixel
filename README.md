<p align="center">
  <img src="https://raw.githubusercontent.com/austineast/echo/gh-pages/logo.png">
</p>

# echo-flixel

Integrate [echo physics](https://austineast.dev/echo/) with [Haxeflixel](https://haxeflixel.com)! 

This library utilizes Haxeflixel's Plugin system to automatically work with the normal flixel workflow. It also adds a new button to Haxeflixel's debugger (click the new "E" icon in the top bar) for easy physics debugging.

## Getting Started

echo-flixel requires [Haxe 4.2+](https://haxe.org/download/) to run.

Install the `echo` and `echo-flixel` libraries from haxelib:

```sh
haxelib install echo
haxelib install echo-flixel
```

Add the library into your `Project.xml`:

```xml
<haxelib name="echo-flixel" />
```

## Usage

FlxEcho needs to be initialized, which should usually be done in your `FlxState`:

```haxe
// using FlxEcho is the preferred way of interacting with the FlxEcho API
using echo.FlxEcho;

class PlayState extends FlxState 
{
  override function create() 
  {
    super.create();

    // Initialize  FlxEcho
    FlxEcho.init({width: FlxG.width, height: FlxG.height, gravity_y: 20});
  }
}
```

You can then add physics bodies to your `FlxObjects`:

```haxe
// Create any kind of Sprite!
var sprite = new FlxSprite();

// Add a physics body
// (make sure you have the `using echo.FlxEcho` import in your hx file)
sprite.add_body();

// Add the Sprite to a FlxGroup
var player_group = new FlxGroup();

// NOTE! - This must be used instead of the normal way of adding objects to FlxGroups (ie - `player_group.add(sprite);`)
sprite.add_to_group(player_group);
```

Lastly, setup a listener and watch your new Physics bodies collide!

```haxe
FlxEcho.listen(player_group, enemy_group);
```

## Example

```haxe
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.FlxState;
import echo.util.verlet.Verlet;

// `using echo.FlxEcho`` is the preferred way of importing the FlxEcho API
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
```

### To check collision with a line (raycast)

```haxe
using echo.FlxEcho;
// ...
var sprite = new FlxSprite();
var body = sprite.add_body();
// create a new line and replace the values where the line starts and ends
var line = echo.Line.get(startX, startY, endX, endY);

var result = sprite.linecast(line);
// linecast returns null if no collision ocurred
if (result != null) {

}

```

Check the `sample` directory for all examples!
