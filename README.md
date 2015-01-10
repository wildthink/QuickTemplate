QuickTemplate
=============

This is a simple template engine for producing simple NSAttributedStrings from
values and named style sets. Its designed to be simple and easy for quick use in
code and creates NSAttributedStrings. If you want HTML use the WebView.

That said. Lets look at a quick example.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
NSDictionary *stylesheet = @{
    @"heavy": @{ NSFontAttributeName: [NSFont boldSystemFontOfSize:12.0] }
};
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



    NSString \*templateString = @"\<s:heavy\>Hello \<v:name/\>\</s:heavy\>\\nHow
    are \<q:LT/\>\<q\>you\</q\>\<q:GT/\>
    today?\\n\<a:http://apple.com\>Apple\</a\>\\nYou are \<value:age/\>";



    id root = @{

        @"name": @"George",

        @"age": @(23),

        @"children": @[@"Elroy", @"Jane"],

        @"true": @YES, @"false": @NO

    };

}
