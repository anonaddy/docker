<?php

use App\Recipient;
use App\User;
use Illuminate\Database\Seeder;
use Illuminate\Foundation\Auth\RegistersUsers;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Ramsey\Uuid\Uuid;

class DatabaseSeeder extends Seeder
{
  /**
   * Run the database seeds.
   *
   * @return void
   */
  public function run()
  {
    $userId = Uuid::uuid4();

    $recipient = Recipient::create([
      'email' => 'anonaddy@example.com',
      'user_id' => $userId
    ]);
    $recipient->markEmailAsVerified();

    User::create([
      'id' => $userId,
      'username' => 'anonaddy',
      'default_recipient_id' => $recipient->id,
      'password' => Hash::make('anonaddy'),
    ]);
  }
}
