module OrderHelper
  def status_for(order)
    klass = case order.status
            when 'pending' then 'warning'
            when 'waiting_confirmation' then 'success'
            when 'on_the_way' then 'success'
            when 'delivered' then 'success'
            when 'internal_failure' then 'danger'
            when 'external_failure' then 'danger'
            end

    content_tag :span, order.status.humanize, class: "label label-#{klass}"
  end

  def options_for_payment_source cards
    cards.map{|card| ["#{card.brand} | #{card.last4}", card.id]}
  end
end
