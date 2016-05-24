#!/bin/sh

quote[0]="Some things Man was never meant to know. For everything else, there's Google."
quote[1]="The Linux philosophy is 'Laugh in the face of danger. Oops. Wrong One. 'Do it yourself'. Yes, that's it.  -- Linus Torvalds"
quote[2]="... one of the main causes of the fall of the Roman Empire was that, lacking zero, they had no way to indicate successful termination of their C programs. -- Robert Firth"
quote[3]="There are 10 kinds of people in the world, those that understand trinary, those that don't, and those that confuse it with binary."
quote[4]="My software never has bugs. It just develops random features."
quote[5]="The only problem with troubleshooting is that sometimes trouble shoots back."
quote[6]="If you give someone a program, you will frustrate them for a day; if you teach them how to program, you will frustrate them for a lifetime."
quote[7]="You know you're a geek when... You try to shoo a fly away from the monitor with your cursor. That just happened to me. It was scary."
quote[8]="We all know Linux is great... it does infinite loops in 5 seconds. - Linus Torvalds about the superiority of Linux on the Amterdam Linux Symposium"
quote[9]="By golly, I'm beginning to think Linux really *is* the best thing since sliced bread.  -- Vance Petree, Virginia Power"

function print_random_quote()
{
    local num_quotes=${#quote[@]};
    local rand=$[ ( $RANDOM % $num_quotes ) + 1 ];      # Generate a random quote number in range
 
    # Display the random quote from case statement, and format it to line wrap at 80 characters
    echo "${quote[$rand]}";
}

print_online_quote()
{
    url='http://www.quotedb.com/quote/quote.php?action=random_quote_rss'
    php_cwd=`/usr/bin/php << 'EOF'
    <?php
        require_once 'rss_php.php';
        $rss = new rss_php;
        $rss->load('http://www.quotedb.com/quote/quote.php?action=random_quote_rss');
        $rssitems = $rss->getItems();

        if ($rssitems) {
                // print_r($rssitems);
                echo $rssitems[0]['description'].' :: '.$rssitems[0]['title']."\n";
        }
    ?>
    EOF`
}
print_online_quote;
