"use client";

import {
  Loader2,
  LogOutIcon,
  SettingsIcon,
  Smartphone,
  Trash2Icon,
} from "lucide-react";
import { useState, useTransition } from "react";
import { toast } from "sonner";
import { deleteAccount } from "@/actions/deleteAccount";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-button";
import { OMNIBIN_ROUTES } from "@/routes";
import { ThemeToggle } from "./theme-toggle";
import { Button } from "./ui/button";

export function ContextMenu({ loggedIn }: { loggedIn: boolean }) {
  const [loggingOut, setLoggingOut] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);

  const handleDeleteAccount = () => {
    setShowDeleteDialog(true);
  };

  const confirmDeleteAccount = () => {
    startTransition(async () => {
      let result: { success: boolean; error?: string } | undefined;
      try {
        result = await deleteAccount();

        if (result.success) {
          // Close dialog first, then redirect after ensuring server action completes
          setShowDeleteDialog(false);
          // Wait longer in production to ensure server action fully completes
          setTimeout(() => {
            window.location.href = OMNIBIN_ROUTES.LOGOUT;
          }, 1000);
        } else {
          // Parse the error to provide more specific feedback
          const errorMessage = result.error || "Unknown error occurred";

          if (
            errorMessage.includes("Auth0") ||
            errorMessage.includes("auth0")
          ) {
            toast.error("Partial deletion completed", {
              description:
                "Your bin items and files were deleted, but the Auth0 account couldn't be removed. Please contact support@omnib.in for assistance.",
              duration: Infinity,
            });
          } else if (
            errorMessage.includes("database") ||
            errorMessage.includes("Database")
          ) {
            toast.error("Partial deletion completed", {
              description:
                "Your Auth0 account was deleted, but some data may remain in our database. Please contact support@omnib.in for assistance.",
              duration: Infinity,
            });
          } else if (
            errorMessage.includes("S3") ||
            errorMessage.includes("storage")
          ) {
            toast.error("Partial deletion completed", {
              description:
                "Your account and bin items were deleted, but some files may remain in storage. Please contact support@omnib.in for assistance.",
              duration: Infinity,
            });
          } else {
            toast.error("Account deletion failed", {
              description: `${errorMessage}. Please contact support@omnib.in for further assistance.`,
              duration: Infinity,
            });
          }
        }
      } catch {
        toast.error("An unexpected error occurred", {
          description:
            "Please contact support@omnib.in for assistance with account deletion.",
          duration: Infinity,
        });
      } finally {
        // Only close dialog if not already closed by success case
        if (!result?.success) {
          setShowDeleteDialog(false);
        }
      }
    });
  };

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="outline" size="icon" className="p-3">
            <SettingsIcon className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent
          className="w-56"
          align="start"
          collisionPadding={12}
        >
          <DropdownMenuItem
            className="cursor-pointer"
            onClick={() => {
              window.open(
                "https://apps.apple.com/us/app/omnibin/id6752793228",
                "_blank"
              );
            }}
          >
            <Smartphone className="size-3" />
            iOS App
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          {loggedIn && (
            <>
              <DropdownMenuItem
                className="cursor-pointer"
                onClick={() => {
                  setLoggingOut(true);
                  window.location.href = OMNIBIN_ROUTES.LOGOUT;
                }}
              >
                {loggingOut ? (
                  <Loader2 className="size-3 animate-spin" />
                ) : (
                  <LogOutIcon className="size-3" />
                )}
                Log out
              </DropdownMenuItem>
              <DropdownMenuItem
                className="cursor-pointer text-red-400 focus:text-red-400"
                onClick={handleDeleteAccount}
                disabled={isPending}
              >
                {isPending ? (
                  <Loader2 className="size-3 animate-spin" />
                ) : (
                  <Trash2Icon className="size-3 text-red-400 focus:text-red-400" />
                )}
                Delete Account
              </DropdownMenuItem>
              <DropdownMenuSeparator />
            </>
          )}
          <ThemeToggle />
        </DropdownMenuContent>
      </DropdownMenu>
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-red-400">
              <Trash2Icon className="size-5 text-red-400" />
              Delete Account
            </DialogTitle>
            <DialogDescription>
              Are you sure you want to delete your account? This action cannot
              be undone and will permanently delete all your data, including:
            </DialogDescription>
          </DialogHeader>
          <div className="my-4 space-y-2 text-sm text-muted-foreground">
            <ul className="list-disc list-inside space-y-1">
              <li>All your bin items (text, images, files, etc.)</li>
              <li>All uploaded files from storage</li>
              <li>Your account and authentication data</li>
            </ul>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDeleteDialog(false)}
              disabled={isPending}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={confirmDeleteAccount}
              disabled={isPending}
              className="bg-red-400 hover:bg-red-500"
            >
              {isPending ? (
                <>
                  <Loader2 className="size-4 animate-spin mr-2" />
                  Deleting...
                </>
              ) : (
                <>
                  <Trash2Icon className="size-4 mr-2" />
                  Delete Account
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
