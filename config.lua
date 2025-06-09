Config = {}

Config.Promp = {
    Play = "Play Music",
    Collect =  "Collect",
    Controls =  "Phonograph Controls",
}

Config.Text = {
    Phono = "Phonograph",
    Picked = "You have saved your phonograph",
    Dont = "This phonograph is not yours",
}

Config.Menu ={
    Play = "Play",
    Stop = "Stop",
    SongList = "Choose a Song",
    DesSongList = "Play a predefined song",
    VolumeUp = "Volume Up",
    VolumeDown = "Volume Down",
    DesPlay = "Play music from a URL",
    DesStop = "Stop the current music",
    DesVolumeUp = "Increase the volume",
    DesVolumeDown = "Decrease the volume",
    Title = "Phonograph",
    SubTx = "Play Music",
    Button = "Play",
    PlaceHolder = "https://www.youtube.com/watch?v=...",
    InputHeader = "Enter the music URL",
    Titles = "Please enter a valid URL",
    Confirm = "Confirm",
    MinMax = "0.01 to 5",
    Change = "Only numbers allowed (0.01 - 5)",
    Speed = "Change Speed",
    Cancel = "Placement cancelled.",
    Placed = "Phonograph placed!",

}

Config.Notify = {
    Phono = "Phonograph",
    PlayMessage = "Music is playing",
    InvalidUrlMessage = "Invalid Url",
    InvalidSound = "Invalid song data",
    StopMessage = "Music stopped",
    VolumeUpMessage = "Volume increased to %d%%",
    MaxVolumeMessage = "Volume is already at maximum.",
    VolumeDownMessage = "Volume decreased to %d%%",
    MinVolumeMessage = "Volume is already at minimum.",
    UnregisteredMessage = "Phonograph not registered!",
    NoPhonographMessage = "No valid phonograph in front of you",
    Already = "You've already placed a phonograph!",
    Placed = "Placement cancelled",
    Place = "Phonograph placed!",
    Custom = "Custom songs are disabled",
}

Config.AllowCustomSongs = true -- If set to false, people will not be able to play their own songs, only those from the Choose a Song list
Config.AllowListSongs = true  -- if set to true, the list of songs from Config.SongList will appear in the menu; if set to false, the option to choose a song will not be shown

Config.SongList = {
    { label = "Émile Waldteufel - Estudiantina", url = "https://youtu.be/q6R5M52lqlw?list=PLJe4EftqVf-ujHNCbcZBwRvwkYuiuHuGl" },
    { label = "Johann Strauss - The Bat Waltz", url = "https://www.youtube.com/watch?v=QVC1jMRVNAw" },
    { label = "Johann Strauss - Voices of Spring", url = "https://www.youtube.com/watch?v=Vh0KkW42iiY" },
    { label = "Johann Strauss - The Blue Danube", url = "https://www.youtube.com/watch?v=o915AjZtZy4" },
    { label = "Johann Strauss - Tales from the Woods", url = "https://www.youtube.com/watch?v=yZGfZDyHkM0" },
    { label = "Johann Strauss - Accelerations", url = "https://www.youtube.com/watch?v=PscKxtzI3Ok" },
    { label = "Johann Strauss - Artist's Life", url = "https://www.youtube.com/watch?v=AQWkpwE2lqA" },
    { label = "Johann Strauss - Eat, Drink and Be Merry", url = "https://www.youtube.com/watch?v=_YRAIphouQY" },
    { label = "Johann Strauss - Emperor Waltz", url = "https://www.youtube.com/watch?v=f91F2RKO7fQ" },
    { label = "Amazing Grace", url = "https://www.youtube.com/watch?v=QJSIlhxksAQ" },
    { label = "Red River Valley", url = "https://www.youtube.com/watch?v=YdussoFmKC0" },
    { label = "I Wish I Was In Dixie Land", url = "https://youtu.be/5OKdbc0DYpM?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Oh! Susanna", url = "https://youtu.be/-9qRad6pWQI?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Little Brown Jug", url = "https://youtu.be/07T7rREzYMc?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Take Me Home", url = "https://youtu.be/DOo-qDb_me0?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "The Rose of Alabama", url = "https://youtu.be/Pr1QnXGTk-o?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Oh! Dem Golden Slippers!", url = "https://youtu.be/cUZ5XzsHN-c?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Camptown Races", url = "https://youtu.be/49_QHBR4OxE?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "In The Garden", url = "https://www.youtube.com/watch?v=ob3P0odQ7Ic" },
    { label = "Yellow Rose of Texas", url = "https://youtu.be/6HgMXpYYUjo?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Carry Me Back to Old Virginny", url = "https://youtu.be/PyhQYOxTHaw?list=PLCyUlNkbObRZ4k-tEvaLwrNmjUcsQPhfE" },
    { label = "Shall We Gather at the River", url = "https://www.youtube.com/watch?v=JfUYN0F5jEI" },
    { label = "Gerardo Nuñez - Remache", url = "https://www.youtube.com/watch?v=HgR_jvjPkAo" },
    { label = "Under the Stars", url = "https://www.youtube.com/watch?v=v4Heu4XMN-g" },
    { label = "Cherokee Morning Song - Walela", url = "https://www.youtube.com/watch?v=96sU0HW8JrE" },
    { label = "Chant of Happiness & Hope", url = "https://www.youtube.com/watch?v=6nOPPuuWBec" },
    { label = "Lakota National Anthem", url = "https://www.youtube.com/watch?v=T-0vfrxkrxg" },
    { label = "Zuni Sunrise", url = "https://www.youtube.com/watch?v=UWcqYlzMg0g" },
    { label = "Lakota Love Song", url = "https://www.youtube.com/watch?v=bUHJ9dxM9_g" },   
}
