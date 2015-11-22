$(function(){
  if (!$('body').hasClass('orders')) { return; }

  var newCreditCardWrapper = $('#payment-info');
  var addNewCardBtn        = $('#add-payment');
  var cancelNewCardBtn     = $('#cancel-add-payment');
  var sourceSelectInput    = $('[name="order[source_id]"]');

  function cancelNewCard() {
    newCreditCardWrapper.hide();
    addNewCardBtn.show();
    newCreditCardWrapper.data('enabled', false);
    cancelNewCardBtn.hide();
    $('.form-control', newCreditCardWrapper).val(null);
  }

  addNewCardBtn.on('click', function(){
    newCreditCardWrapper.show();
    addNewCardBtn.hide();
    sourceSelectInput.val(null);
    newCreditCardWrapper.data('enabled', true);
    cancelNewCardBtn.show();
  });

  cancelNewCardBtn.on('click', cancelNewCard);
  sourceSelectInput.on('change', cancelNewCard);
});
