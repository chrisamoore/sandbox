<?php
    use Illuminate\Support\Facades\Hash;

    /**
     * Class UserSeeder
     *  */
    class UserSeeder extends DatabaseSeeder {
        public function run(){
            $users = [
                [
                    'username' => 'cmoore',
                    'password' => Hash::make('password'),
                    'email' => 'chris@camdesigns.net'
                ]
            ];

            foreach($users as $user){
                User::create($user);
            }
        }
    }
 