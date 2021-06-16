jQuery.fn.filterByText = function(textbox, selectSingleMatch) {
    return this.each(function() {
        var select = this;
        var options = [];
        $(select).find('option').each(function() {
            options.push({value: $(this).val(), text: $(this).text()});
        });
        $(select).data('options', options);
        $(textbox).bind('change keyup', function() {
            var options = $(select).empty().data('options');
            var search = $(this).val().trim();
            var regex = new RegExp(search,"gi");
          
            $.each(options, function(i) {
                var option = options[i];
                if(option.text.match(regex) !== null) {
                    $(select).append(
                       $('<option>').text(option.text).val(option.value)
                    );
                }
            });
            if (selectSingleMatch === true && $(select).children().length === 1) {
                $(select).children().get(0).selected = true;
            }
        });            
    });
};

/*
 
 <input id="textbox" type="text" />
<select id="select">
  <option class="1" value="1">1</option>
  <option class="2" value="234567890">234567890</option>
  <option class="3" value="better">better</option>
  <option class="4" value="world">world</option>
  <option class="5" value="goodly deeds">goodly deeds</option>
  </select>
 
   $(function() {
        $('#select').filterByText($('#textbox'), false);
    });
  
 */