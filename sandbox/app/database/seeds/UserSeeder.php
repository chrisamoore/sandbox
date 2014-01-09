<?php
    use Illuminate\Support\Facades\Hash;

    /**
 * @author Christopher A. Moore <@undergroundelephant.com>
 * @date 1/8/14
 * @copyright Underground Elephant 2014
 */

/**
 * Class UserSeeder
 *  */
class UserSeeder
{
    public function run(){
        $users = [
            [
                'username' => 'cmoore',
                'password' => Hash::make('password'),
                'email'    => 'chris@camdesigns.net'
            ]
        ];

        foreach ($users as $user) {
            User::create($user);
        }
    }
}
 