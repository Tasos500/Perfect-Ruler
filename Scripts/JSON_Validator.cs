using Godot;
using System;
using System.IO;
using System.Text;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Schema;

public class JSON_Validator : Node
{

    public bool ValidateJson(String databaseLocation)
    {
        Godot.File schemaFile = new Godot.File();
        schemaFile.Open("res://Assets/Perfect Ruler Schema.json", Godot.File.ModeFlags.Read);
        JSchema schema = JSchema.Parse(schemaFile.GetAsText());

        // Read Database
        Godot.File databaseFile = new Godot.File();
        databaseFile.Open(databaseLocation, Godot.File.ModeFlags.Read);
        JObject database = JObject.Parse(databaseFile.GetAsText());
        

        // Validate Database
        bool valid = database.IsValid(schema);

        databaseFile.Close();
        schemaFile.Close();

        return valid;
    }

// Called when the node enters the scene tree for the first time.
public override void _Ready()
    {
        
    }

//  // Called every frame. 'delta' is the elapsed time since the previous frame.
//  public override void _Process(float delta)
//  {
//      
//  }
}
