package arm2d;

// Zui
import zui.Canvas;

// Editor
import arm2d.Path;
import arm2d.ui.UIProperties;

class Assets {

	public static function getImage(asset:TAsset):kha.Image {
		return Canvas.assetMap.get(asset.id);
	}

	public static function importAsset(canvas:TCanvas, path:String) {
		var isImage = StringTools.endsWith(path, ".jpg") ||
					  StringTools.endsWith(path, ".png") ||
					  StringTools.endsWith(path, ".k") ||
					  StringTools.endsWith(path, ".hdr");

		var isFont = StringTools.endsWith(path, ".ttf");

		var abspath = Path.toAbsolute(path, Main.cwd);
		abspath = kha.System.systemId == "Windows" ? StringTools.replace(abspath, "/", "\\") : abspath;

		if (isImage) {
			kha.Assets.loadImageFromPath(abspath, false, function(image:kha.Image) {
				var ar = path.split("/");
				var name = ar[ar.length - 1];
				var asset:TAsset = { name: name, file: path, id: Canvas.getAssetId(canvas) };
				canvas.assets.push(asset);
				Canvas.assetMap.set(asset.id, image);

				Editor.assetNames.push(name);
				UIProperties.hwin.redraws = 2;
			});
		}
		else if (isFont) {
			kha.Assets.loadFontFromPath(abspath, function(font:kha.Font) {
				var ar = path.split("/");
				var name = ar[ar.length - 1];
				var asset:TAsset = { name: name, file: path, id: Canvas.getAssetId(canvas) };
				canvas.assets.push(asset);
				Canvas.assetMap.set(asset.id, font);

				Editor.assetNames.push(name);
				UIProperties.hwin.redraws = 2;
			});
		}
	}

	/**
	 * Imports all themes from '_themes.json'. If the file doesn't exist, the
	 * default light theme is used instead.
	 */
	public static function importThemes() {
		var themesDir = haxe.io.Path.directory(Main.prefs.path);
		var themesPath = haxe.io.Path.join([themesDir, "_themes.json"]);

		try {
			kha.Assets.loadBlobFromPath(themesPath, function(b:kha.Blob) {
				Canvas.themes = haxe.Json.parse(b.toString());

				if (Canvas.themes.length == 0) {
					Canvas.themes.push(Reflect.copy(zui.Themes.light));
				}
				if (Main.inst != null) Editor.selectedTheme = Canvas.themes[0];

			// Error handling for HTML5 target
			}, function(a:kha.AssetError) {
				Canvas.themes.push(Reflect.copy(zui.Themes.light));
				if (Main.inst != null) Editor.selectedTheme = Canvas.themes[0];
			});
		}
		// Error handling for Krom, as the failed callback for loadBlobFromPath()
		// is currently not implemented in Krom
		catch (e: Dynamic) {
			Canvas.themes.push(Reflect.copy(zui.Themes.light));
			if(Main.inst != null) Editor.selectedTheme = Canvas.themes[0];
		}
	}

	public static function save(canvas: TCanvas) {
		// Unpan
		canvas.x = 0;
		canvas.y = 0;

		saveCanvas(canvas);
		saveAssets(canvas);
		saveThemes();

		canvas.x = Editor.coffX;
		canvas.y = Editor.coffY;
	}

	static function saveCanvas(canvas: TCanvas) {
		#if kha_krom
		Krom.fileSaveBytes(Main.prefs.path, haxe.io.Bytes.ofString(haxe.Json.stringify(canvas)).getData());

		#elseif kha_debug_html5
		html5WriteFile(Main.prefs.path, haxe.Json.stringify(canvas));
		#end
	}

	static function saveAssets(canvas: TCanvas) {
		var filesPath = Main.prefs.path.substr(0, Main.prefs.path.length - 5); // .json
		filesPath += '.files';

		var filesList = '';
		for (a in canvas.assets) filesList += a.file + '\n';

		#if kha_krom
		Krom.fileSaveBytes(filesPath, haxe.io.Bytes.ofString(filesList).getData());

		#elseif kha_debug_html5
		html5WriteFile(filesPath, filesList);
		#end
	}

	static function saveThemes() {
		var themesPath = haxe.io.Path.join([haxe.io.Path.directory(Main.prefs.path), "_themes.json"]);

		#if kha_krom
		Krom.fileSaveBytes(themesPath, haxe.io.Bytes.ofString(haxe.Json.stringify(Canvas.themes)).getData());

		#elseif kha_debug_html5
		html5WriteFile(themesPath, haxe.Json.stringify(Canvas.themes));
		#end
	}

	#if kha_debug_html5
	static function html5WriteFile(filePath: String, data: String) {
		var fs = untyped __js__('require("fs");');
		var path = untyped __js__('require("path")');

		var filePath = path.resolve(untyped __js__('__dirname'), filePath);

		try { fs.writeFileSync(filePath, data); }
		catch (x: Dynamic) { trace('saving "${filePath}" failed'); }
	}
	#end

	public static function getEnumTexts():Array<String> {
		if(Main.inst==null) return [""];
		return Editor.assetNames.length > 0 ? Editor.assetNames : [""];
	}

	public static function getAssetIndex(canvas:TCanvas, asset:String):Int {
		for (i in 0...canvas.assets.length) if (asset == canvas.assets[i].name) return i + 1; // assetNames[0] = ""
		return 0;
	}
}
