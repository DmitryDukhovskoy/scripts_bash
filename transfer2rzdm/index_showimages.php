<?php
    $dir = './';
    $file_display = array('png');

// Set space between images
    $myspace =10;  // put space NN px

    if (file_exists($dir) == false)
    {
        echo 'Directory "', $dir, '" not found!';
    }
    else
    {
        $dir_contents = scandir($dir);

        foreach ($dir_contents as $file)
        {
            $file_type = strtolower(end(explode('.', $file)));
            if ($file !== '.' && $file !== '..' && in_array($file_type, $file_display) == true)
            {
                $name = basename($file);
                echo "<img src='img.php?name={$name}' width='600' height='600'/>";

             // Print the desired space between images
            //  echo '<div style="width: ' . $myspace . 'px"></div>';
            //    echo "<br>";
            }
        }
    }
?>
