import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

using echo.FlxEcho;

class BarTestState extends FlxState {

  var horizontalBar:FlxSprite;

  override function create() {
    super.create();

    FlxG.camera.bgColor = FlxColor.CYAN;

    FlxEcho.init({ width: 800, height: 600 });
    horizontalBar = new FlxSprite();
    horizontalBar.loadGraphic(AssetPaths.horizontal_bar__png);
    horizontalBar.add_body();
    horizontalBar.get_body().set_position(50, 50);
    // horizontalBar.get_body().shape.transform.set_dirty(true);
    add(horizontalBar);
  }

  override function update(elapsed:Float) {
    super.update(elapsed);

    if (FlxG.keys.pressed.DOWN) horizontalBar.get_body().y += 1;
    if (FlxG.keys.pressed.UP) horizontalBar.get_body().y -= 1;
    if (FlxG.keys.pressed.RIGHT) horizontalBar.get_body().x += 1;
  }
}