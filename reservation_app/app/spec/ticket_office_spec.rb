require 'spec_helper'

def free_seat(coach: 'A', seat_number: '1')
  { 'coach' => coach, 'seat_number' => seat_number, 'booking_reference' => "" }
end

def reserved_seat(coach: 'A', seat_number: '1', reservation_number: "1234567")
  { 'coach' => coach, 'seat_number' => seat_number, 'booking_reference' => reservation_number }
end

describe TicketOffice do
  let(:train_data_service) { double('TrainDataService') }
  let(:booking_reference_service) { double('BookingReferenceNumber') }
  let(:seat_list) do
    {
      '1A' => free_seat(coach: 'A', seat_number: '1'),
      '2A' => free_seat(coach: 'A', seat_number: '2'),
      '3A' => free_seat(coach: 'A', seat_number: '2')
    }
  end

  let(:reservation_number) { '123456' }
  let(:train_id) { 'express_2000' }
  let(:seats) { 1 }

  let(:ticket_office) { TicketOffice.new(train_data_service, booking_reference_service) }
  subject(:reservation) { ticket_office.make_reservation(train_id: train_id, number_of_seats_to_reserve: seats) }

  before do
    allow(train_data_service).to receive(:train).with(train_id).and_return(seat_list)
    allow(train_data_service).to receive(:reserve)
    allow(booking_reference_service).to receive(:reservation_number).and_return(reservation_number)
  end

  describe 'Reserve one seat in train' do
    let(:train_id) { 'express_2000' }
    let(:seats) { 1 }
    let(:seat_list) do
      {
        '1A' => free_seat(coach: 'A', seat_number: '1'),
        '2A' => free_seat(coach: 'A', seat_number: '2'),
        '3A' => free_seat(coach: 'A', seat_number: '3')
      }
    end


    it 'reserves seat 1A' do
      expect(reservation).to have_attributes(seats: %w[1A], train_id: 'express_2000')
    end
  end

  describe 'Reserve two seats in train' do
    let(:train_id) { 'express_2000' }
    let(:seats) { 2 }
    let(:seat_list) do
      {
        '1A' => free_seat(coach: 'A', seat_number: '1'),
        '2A' => free_seat(coach: 'A', seat_number: '2'),
        '3A' => free_seat(coach: 'A', seat_number: '3'),
        '4A' => free_seat(coach: 'A', seat_number: '4'),
        '5A' => free_seat(coach: 'A', seat_number: '5')
      }
    end


    it 'reserves seats 1A and 2A' do
      expect(reservation).to have_attributes(seats: %w[1A 2A], train_id: 'express_2000')
    end
  end

  it 'send reservation to train data service' do
    expect(train_data_service).to receive(:reserve).with(train_id, %w[1A], reservation_number)
    reservation
  end

  describe 'do not reserve seats if train is more than 70% full' do
    let(:train_id) { 'express_2000' }
    let(:seats) { 1 }
    let(:seat_list) do
      {
        '1A' => reserved_seat(coach: 'A', seat_number: '1'),
        '2A' => reserved_seat(coach: 'A', seat_number: '2'),
        '3A' => reserved_seat(coach: 'A', seat_number: '3'),
        '4A' => reserved_seat(coach: 'A', seat_number: '4'),
        '5A' => free_seat(coach: 'A', seat_number: '5')
      }
    end

    it 'does not send reservation to train data service' do
      expect(train_data_service).not_to receive(:reserve)
      reservation
    end

    it 'reserve no seats' do
      expect(reservation).to have_attributes(seats: [], train_id: 'express_2000')
    end
  end

  describe 'do not reserve seats if train is exactly 70% full' do
    let(:train_id) { 'express_2000' }
    let(:seats) { 1 }
    let(:seat_list) do
      {
        '1A' => reserved_seat(coach: 'A', seat_number: '1'),
        '2A' => reserved_seat(coach: 'A', seat_number: '2'),
        '3A' => reserved_seat(coach: 'A', seat_number: '3'),
        '4A' => reserved_seat(coach: 'A', seat_number: '4'),
        '5A' => reserved_seat(coach: 'A', seat_number: '5'),
        '6A' => reserved_seat(coach: 'A', seat_number: '6'),
        '7A' => reserved_seat(coach: 'A', seat_number: '7'),
        '8A' => free_seat(coach: 'A', seat_number: '8'),
        '9A' => free_seat(coach: 'A', seat_number: '9'),
        '10A' => free_seat(coach: 'A', seat_number: '10')
      }
    end

    it 'does not reserves seats' do
      expect(reservation).to have_attributes(seats: [], train_id: 'express_2000')
      expect(train_data_service).not_to receive(:reserve)
    end
  end

  describe 'Do not reserve seats if the final capacity would be over 70%' do
    let(:seats) { 2 }
    let(:seat_list) do
      {
        '1A' => reserved_seat(coach: 'A', seat_number: '1'),
        '2A' => reserved_seat(coach: 'A', seat_number: '2'),
        '3A' => free_seat(coach: 'A', seat_number: '3'),
        '4A' => free_seat(coach: 'A', seat_number: '4'),
        '5A' => free_seat(coach: 'A', seat_number: '5')
      }
    end

    it 'does not reserves seats' do
      expect(reservation).to have_attributes(seats: [], train_id: 'express_2000')
      expect(train_data_service).not_to receive(:reserve)
    end
  end

  describe 'reserve seats in same coach' do
    let(:seats) { 2 }
    let(:seat_list) do
      {
        '1A' => reserved_seat(coach: 'A', seat_number: '1'),
        '2A' => reserved_seat(coach: 'A', seat_number: '2'),
        '3A' => free_seat(coach: 'A', seat_number: '3'),
        '1B' => free_seat(coach: 'B', seat_number: '1'),
        '2B' => free_seat(coach: 'B', seat_number: '2'),
        '3B' => free_seat(coach: 'B', seat_number: '3'),
        '4B' => free_seat(coach: 'B', seat_number: '4')
      }
    end

    it 'reserves seats 1B and 2B' do
      expect(reservation).to have_attributes(seats: %w[1B 2B], train_id: train_id)
    end
  end

  context 'train with tree coaches occupied from ~45%' do
    let(:seats) { 2 }
    let(:seat_list) do
      {
        '1A' => reserved_seat(coach: 'A', seat_number: '1'),
        '2A' => reserved_seat(coach: 'A', seat_number: '2'),
        '1B' => reserved_seat(coach: 'B', seat_number: '2'),
        '2B' => free_seat(coach: 'B', seat_number: '1'),
        '1C' => free_seat(coach: 'C', seat_number: '1'),
        '2C' => free_seat(coach: 'C', seat_number: '2'),
        '3C' => free_seat(coach: 'C', seat_number: '3'),
        '4C' => free_seat(coach: 'C', seat_number: '4')
      }
    end
    describe 'reserve seats in same coach' do
      it 'reserves seats 1C and 2C' do
        expect(reservation).to have_attributes(seats: %w[1C 2C], train_id: train_id)
      end
    end
  end
end
