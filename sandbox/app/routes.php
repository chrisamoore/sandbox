<?php

/*
|--------------------------------------------------------------------------
| Application Routes
|--------------------------------------------------------------------------
|
| Here is where you can register all of the routes for an application.
| It's a breeze. Simply tell Laravel the URIs it should respond to
| and give it the Closure to execute when that URI is requested.
|
*/

Route::group(["before"=>"guest"], function(){
	Route::any('/',[
		'as' => 'user/login',
		'uses' => 'UserController@loginAction'
	]);

	Route::any('/request',[
		'as' => 'user/request',
		'uses' => 'UserController@requestAction'
	]);

	Route::any('/reset',[
		'as' => 'user/reset',
		'uses' => 'UserController@resetAction'
	]);
});

Route::group(["before"=>"auth"],function() {
    Route::any("/profile", [
		"as"   => "user/profile",
        "uses" => "UserController@profileAction"
    ]);
    Route::any("/logout", [
        "as"   => "user/logout",
        "uses" => "UserController@logoutAction"
	]);
});

Route::any("/group/index",[
	"as" => "group/index",
	"uses" => "GroupController@indexAction"
]);

Route::any("/group/edit",[
	"as" => "group/edit",
	"uses" => "GroupController@editAction"
]);

Route::any("/group/delete",[
	"as" => "group/delete",
	"uses" => "GroupController@deleteAction"
]);


// Route::group(["before" => "guest"], function()
// {
//     $resources = Resource::where("secure", false)->get();

//     foreach ($resources as $resource)
//     {
//         Route::any($resource->pattern, [
//             "as"   => $resource->name,
//             "uses" => $resource->target
//         ]);
//     }
// });

// Route::group(["before" => "auth"], function()
// {
//     $resources = Resource::where("secure", true)->get();

//     foreach ($resources as $resource)
//     {
//         Route::any($resource->pattern, [
//             "as"   => $resource->name,
//             "uses" => $resource->target
//         ]);
//     }
// });
