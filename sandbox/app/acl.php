    <?php

        /*
        |--------------------------------------------------------------------------
        | ACL Resources, Roles, and Permissions
        |--------------------------------------------------------------------------
        |
        | Below you may add resources and roles and define the permissions
        | roles have on those resources.
        |
        */

        // Add Resources
        /**
         *
         * // Add using string shortcut
         * Acl::addResource('page');
         *
         * // Add using instance of the Resource class
         * Acl::addResource(new \Zend\Permissions\Acl\Resource\GenericResource('someResource'));
         *
         */


        // Add Roles
        /**
         *
         * // Add using string shortcut
         * Acl::addRole('admin');
         *
         * // Add using instance of the Role class
         * Acl::addRole(new \Zend\Permissions\Acl\Role\GenericRole('member'));
         *
         */


        // Give roles permissions on resources
        /**
         *
         * // Add page resource
         * Acl::addResource('page');
         *
         * // Add admin role
         * Acl::addRole('admin');
         *
         * // Add guest role
         * Acl::addRole('guest');
         *
         * // Give admin role add, edit, delete, and view permissions for page resource
         * Acl::allow('admin', 'page', array('add', 'edit', 'delete', 'view'));
         *
         * // Give guest role only view permissions for page resource
         * Acl::allow('guest', 'page', 'view');
         *
         */

        /**
         *
         * // Add page resource
         * Acl::addResource('page');
         *
         * // Add admin role
         * Acl::addRole('admin');
         *
         * // Give admin role add, edit, delete, and view permissions for page resource
         * Acl::allow('admin', 'page', array('add', 'edit', 'delete', 'view'));
         *
         * // Add staff role that inheirits from admin
         * Acl::addRole('staff', 'admin');
         *
         * // Deny access for staff role the delete permission on the page resource
         * Acl::deny('staff', 'page', 'delete');
         *
         */

        // Checking for permissions
        /**
         *
         * // Add page resource
         * Acl::addResource('page');
         *
         * // Add admin role
         * Acl::addRole('admin');
         *
         * // Give admin role add, edit, delete, and view permissions for page resource
         * Acl::allow('admin', 'page', array('add', 'edit', 'delete', 'view'));
         *
         * // Add staff role that inheirits from admin
         * Acl::addRole('staff', 'admin');
         *
         * // Deny access for staff role the delete permission on the page resource
         * Acl::deny('staff', 'page', 'delete');
         *
         */

        /**
         *
         * // Check if admin can add page
         * // Should return true
         * $allowed = Acl::isAllowed('admin', 'page', 'add');
         *
         * // Check if admin can delete page
         * // Should return true
         * $allowed = Acl::isAllowed('admin', 'page', 'delete');
         *
         * // Check if guest can edit page
         * // Should return false
         * $allowed = Acl::isAllowed('guest', 'page', 'edit');
         *
         * // Check if guest can view page
         * // Should return true
         * $allowed = Acl::isAllowed('guest', 'page', 'view');
         *
         */