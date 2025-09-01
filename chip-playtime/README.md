# Chip Playtime

This project is a FiveM resource for tracking playtime and managing chips in a server.

## Installation

1. **Download or Clone the Repository**
   - Place the `chip-playtime` folder in your server's `resources` directory.

2. **Database Setup**
   - Import the `playtime.sql` file into your database to create the necessary tables.
   - Example using phpMyAdmin or MySQL command line:
     ```sql
     SOURCE /path/to/chip-playtime/playtime.sql;
     ```

3. **Configuration**
   - Edit `config.lua` to adjust settings as needed for your server.

4. **Add Resource to Server**
   - Add the following line to your `server.cfg`:
     ```
     ensure chip-playtime
     ```

5. **Start the Server**
   - Restart your FiveM server to load the resource.

## Files
- `config.lua`: Configuration options for the resource.
- `fxmanifest.lua`: Resource manifest for FiveM.
- `playtime.sql`: SQL file to set up the database.
- `server.lua`: Main server-side script.

## Support
For issues or questions, please open an issue on the repository or contact the developer.
