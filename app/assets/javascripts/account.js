$(document).on('ready page:load', function(){
  if (!$('body').hasClass('account')) { return; }

  // Credit cards
  (function(){
    var wrapper,
        newCreditCardForm,
        addNewCardBtn,
        cancelNewCardBtn;

    function setup() {
      wrapper           = $('.credit-cards-wrapper');
      newCreditCardForm = $('form', wrapper);
      addNewCardBtn     = $('#add-payment', wrapper);
      cancelNewCardBtn  = $('#cancel-add-payment', wrapper);

      addNewCardBtn.on('click', function(){
        newCreditCardForm.show();
        addNewCardBtn.hide();
      });

      cancelNewCardBtn.on('click', cancelNewCard);

      newCreditCardForm.on('ajax:success', function (ev, data, status, xhr) {
        wrapper.replaceWith(data.html);
        setup();
      });

      newCreditCardForm.on('ajax:error', function (ev, xhr, status, error) {
        wrapper.replaceWith(xhr.responseJSON.html);
        setup();
        addNewCardBtn.trigger('click');
      });
    }

    function cancelNewCard() {
      newCreditCardForm.hide();
      addNewCardBtn.show();
      $('.form-control', newCreditCardForm).val(null);
    }

    setup();
  })();
});
